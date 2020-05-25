%skeleton "lalr1.cc"
%define api.parser.class {conj_parser}
%define api.token.constructor
%define api.value.type variant
%define parse.assert
%define parse.error verbose
%locations

%code requires
{
#include <map>
#include <list>
#include <vector>
#include <string>
#include <iostream>
#include <algorithm>

#define ENUM_IDENTIFIERS(o) \
	o(undefined) \
	o(function) \
	o(parameter) \
	o(variable)

#define o(n) n,
enum class id_type { ENUM_IDENTIFIERS(o) };
#undef o

struct identifier
{
	id_type type =	id_type::undefined;
	std::size_t		index = 0;
	std::string		name;
};

#define ENUM_EXPRESSIONS(o) \
	o(nop) o(string) o(number) o(ident) \
	o(add) o(neg) o(eq) \
	o(cor) o(cand) o(loop) \
	o(addrof) o(deref) \
	o(fcall) \
	o(copy) \
	o(comma) \
	o(ret)

#define o(n) n,
enum class ex_type { ENUM_EXPRESSIONS(o) };
#undef o

typedef std::list<struct expression> expr_vec;
struct expression
{
	ex_type			type;
	identifier		ident{};
	std::string		strvalue{};
	long			numvalue = 0;
	expr_vec		params;

	template<typename... T>
	expression(ex_type t, T&&... args) : type(t), params {std::forward<T>(args)... } {} 

	expression()					: type(ex_type::nop) {}
	expression(const identifier& i)	: type(ex_type::ident), ident(i) {}
	expression(identifier&& i)		: type(ex_type::ident), ident(std::move(i)) {}
	expression(std::string&& s)		: type(ex_type::string), strvalue(std::move(s)) {}
	expression(long v)				: type(ex_type::number), numvalue(v) {}

	bool is_pure() const;
	expression operator %=(expression&& b) && { return expression(ex_type::copy, std::move(b), std::move(*this)); }
};

#define o(n) \
template<typename... T>\
inline expression e_##n(T&&... args) { return expression(ex_type::n, std::forward<T>(args)...); }
ENUM_EXPRESSIONS(o)
#undef o

struct function
{
	std::string name;
	expression code;
	unsigned num_vars = 0, num_params = 0;
};

struct lexcontext;
int goparse(const char *_inputname);

}//%code requires

%param {
	lexcontext& ctx
} //%param

%code
{
struct lexcontext
{
	const char* cursor;
	yy::location loc;
	std::vector<std::map<std::string, identifier>> scopes;
	std::vector<function> func_list;
	unsigned tempcounter = 0;
	function fun;
public:
	const identifier& define(const std::string& name, identifier&& f)
	{
		auto r = scopes.back().emplace(name, std::move(f));
		if (!r.second) throw yy::conj_parser::syntax_error(loc, "Duplicate definition '"+name+"'");
		return r.first->second;
	}
	expression def(const std::string& name)		{ return define(name, identifier{id_type::variable, fun.num_vars++, name}); }
	expression defun(const std::string& name)	{ return define(name, identifier{id_type::function, func_list.size(), name}); }
	expression defparm(const std::string& name)	{ return define(name, identifier{id_type::parameter, fun.num_params++, name}); }
	expression temp()							{ return def("$I"+std::to_string(tempcounter++)); }
	expression use(const std::string& name)
	{
		for (auto j=scopes.crbegin(); j!=scopes.crend(); ++j)
			if (auto i=j->find(name); i!=j->end())
				return i->second;
		throw yy::conj_parser::syntax_error(loc, "Undefined identifier '"+name+"'");
	}
	void add_function(std::string&& name, expression&& code)
	{
		fun.code = e_comma(std::move(code), e_ret(0L));	// implicit return 0;
		fun.name = std::move(name);
		func_list.push_back(std::move(fun));
		fun = {};
	}

	void operator ++() { scopes.emplace_back(); }	// enter scope
	void operator --() { scopes.pop_back(); }		// exit scope
};

namespace yy { conj_parser::symbol_type yylex(lexcontext& ctx); }

#define M(x) std::move(x)
#define C(x) expression(x)

}//%code

%token END 0
%token RETURN "return" WHILE "while" IF "if" VAR "var" IDENTIFIER NUMCONST STRINGCONST
%token OR "||" AND "&&" EQ "==" NE "!=" PP "++" MM "--" PL_EQ "+=" MI_EQ "-="

%left ','
%right '?' ':' '=' "+=" "-="
%left "||"
%left "&&"
%left "==" "!="
%left '+' '-'
%left '*'
%right '&' "++" "--"
%left '(' '['

%type<long>			NUMCONST
%type<std::string>	IDENTIFIER STRINGCONST
%type<expression>	expr exprs c_expr1 stmt var_defs var_def1 com_stmt

%%

library:		{ ++ctx; } functions { --ctx; };
functions:		functions IDENTIFIER { ctx.defun($2); ++ctx; } paramdecls ':' stmt { ctx.add_function(M($2), M($6)); --ctx; }
|				%empty;
paramdecls:		paramdecl
|				%empty;
paramdecl:		paramdecl ',' IDENTIFIER	{ ctx.defparm($3); }
|				IDENTIFIER					{ ctx.defparm($1); };
stmt:			com_stmt  '}'				{ $$ = M($1); --ctx; }
|				"if" '(' exprs ')' stmt		{ $$ = e_cand(M($3), M($5)); }
|				"while" '(' exprs ')' stmt	{ $$ = e_loop(M($3), M($5)); }
|				"return" exprs ';'			{ $$ = e_ret(M($2)); }
|				exprs ';'					{ $$ = M($1); }
|				';'							{ };
com_stmt:		'{'							{ $$ = e_comma(); ++ctx; }
|				com_stmt stmt				{ $$ = M($1); $$.params.push_back(M($2)); };
var_defs:		"var" var_def1				{ $$ = e_comma(M($2)); }
|				var_defs ',' var_def1		{ $$ = M($1); $$.params.push_back(M($3)); };
var_def1:		IDENTIFIER '=' expr			{ $$ = ctx.def($1) %= M($3); }
|				IDENTIFIER					{ $$ = ctx.def($1) %= 0L; };
exprs:			var_defs					{ $$ = M($1); }
|				expr						{ $$ = M($1); }
|				expr ',' c_expr1			{ $$ = e_comma(M($1)); $$.params.splice($$.params.end(), M($3.params)); };
c_expr1:		expr						{ $$ = e_comma(M($1)); }
|				c_expr1 ',' expr			{ $$ = M($1); $$.params.push_back(M($3)); };
expr:			NUMCONST					{ $$ = $1; }
|				STRINGCONST					{ $$ = M($1); }
|				IDENTIFIER					{ $$ = ctx.use($1); }
|				'(' expr ')'				{ $$ = M($2); }
|				expr '[' exprs ']'			{ $$ = e_deref(e_add(M($1), M($3))); }
|				expr '(' ')'				{ $$ = e_fcall(M($1)); }
|				expr '(' c_expr1 ')'		{ $$ = e_fcall(M($1)); $$.params.splice($$.params.end(), M($3.params)); }
|				expr '=' expr				{ $$ = M($1) %= M($3); }
|				expr '+' expr				{ $$ = e_add(M($1), M($3)); }
|				expr '-' expr %prec '+'		{ $$ = e_add(M($1), e_neg(M($3))); }
|				expr "+=" expr				{ if(!$3.is_pure()) { $$ = ctx.temp() %= e_addrof(M($1)); $1 = e_deref($$.params.back()); }
											  $$ = e_comma(M($$), M($1) %= e_add(C($1), M($3))); }
|				expr "-=" expr				{ if(!$3.is_pure()) { $$ = ctx.temp() %= e_addrof(M($1)); $1 = e_deref($$.params.back()); }
											  $$ = e_comma(M($$), M($1) %= e_add(C($1), e_neg(M($3)))); }
|				"++" expr					{ if(!$2.is_pure()) { $$ = ctx.temp() %= e_addrof(M($2)); $2 = e_deref($$.params.back()); }
											  $$ = e_comma(M($$), M($2) %= e_add(C($2), 1L)); }
|				"--" expr %prec "++"		{ if(!$2.is_pure()) { $$ = ctx.temp() %= e_addrof(M($2)); $2 = e_deref($$.params.back()); }
											  $$ = e_comma(M($$), M($2) %= e_add(C($2), -1L)); }
|				expr "++"					{ if(!$1.is_pure()) { $$ = ctx.temp() %= e_addrof(M($1)); $1 = e_deref($$.params.back()); }
											  auto i = ctx.temp(); $$ = e_comma(M($$), C(i) %= C($1), C($1) %= e_add(C($1), 1L), C(i)); }
|				expr "--" %prec "++"		{ if(!$1.is_pure()) { $$ = ctx.temp() %= e_addrof(M($1)); $1 = e_deref($$.params.back()); }
											  auto i = ctx.temp(); $$ = e_comma(M($$), C(i) %= C($1), C($1) %= e_add(C($1), -1L), C(i)); }
|				expr "||" expr				{ $$ = e_cor(M($1), M($3)); }
|				expr "&&" expr				{ $$ = e_cand(M($1), M($3)); }
|				expr "==" expr				{ $$ = e_eq(M($1), M($3)); }
|				expr "!=" expr %prec "=="	{ $$ = e_eq(e_eq(M($1), M($3)), 0L); }
|				'&' expr					{ $$ = e_addrof(M($2)); }
|				'*' expr %prec '&'			{ $$ = e_deref(M($2)); }
|				'-' expr %prec '&'			{ $$ = e_neg(M($2)); }
|				'!' expr %prec '&'			{ $$ = e_eq(M($2), 0L); }
|				expr '?' expr ':' expr		{ auto i = ctx.temp();
											  $$ = e_comma(e_cor(e_cand(M($1), e_comma(C(i) %= M($3), 1L)), C(i) %= M($5)), C(i)); };

%%

yy::conj_parser::symbol_type yy::yylex(lexcontext& ctx)
{
	const char* anchor = ctx.cursor;
	ctx.loc.step();
	auto s = [&](auto func, auto&&... params)
	{
		ctx.loc.columns(ctx.cursor - anchor);
		return func(params..., ctx.loc); 
	};

%{
re2c:yyfill:enable		= 0;
re2c:define:YYCTYPE		= "char";
re2c:define:YYCURSOR	= "ctx.cursor";

// Keywords:
"return"				{ return s(conj_parser::make_RETURN); }
"while" | "for"			{ return s(conj_parser::make_WHILE); }
"var"					{ return s(conj_parser::make_VAR); }
"if"					{ return s(conj_parser::make_IF); }

// Identifiers
[a-zA-Z] [a-zA-Z_0-9]*	{ return s(conj_parser::make_IDENTIFIER, std::string(anchor, ctx.cursor)); }

// String and integer literals
"\"" [^\"]* "\""		{ return s(conj_parser::make_STRINGCONST, std::string(anchor+1, ctx.cursor-1)); }
[0-9]+					{ return s(conj_parser::make_NUMCONST, std::stol(std::string(anchor, ctx.cursor))); }

// Whitespace and comments
"\000"					{ return s(conj_parser::make_END); }
"\r\n" | [\r\n]			{ ctx.loc.lines(); return yylex(ctx); }
"//" [^\r\n]*			{ return yylex(ctx); }
[\t\v\b\f ]				{ ctx.loc.columns(); return yylex(ctx); }

// Multi-char operators
"&&"					{ return s(conj_parser::make_AND); }
"||"					{ return s(conj_parser::make_OR); }
"++"					{ return s(conj_parser::make_PP); }
"--"					{ return s(conj_parser::make_MM); }
"!="					{ return s(conj_parser::make_NE); }
"=="					{ return s(conj_parser::make_EQ); }
"+="					{ return s(conj_parser::make_PL_EQ); }
"-="					{ return s(conj_parser::make_MI_EQ); }
.						{ return s([](auto...s){return conj_parser::symbol_type(s...);}, conj_parser::token_type(ctx.cursor[-1]&0xFF)); }
%}
}

void yy::conj_parser::error(const location_type& l, const std::string& m)
{
	std::cerr << (l.begin.filename ? l.begin.filename->c_str() : "undefined");
	std::cerr << ":" << l.begin.line << ":" << l.begin.column << "-" << l.end.column << ": " << m << "\n";
}

#include <fstream>

bool expression::is_pure() const
{
	for(const auto& e : params) if (!e.is_pure()) return false;
	switch(type)
	{
		case ex_type::fcall:	return false;
		case ex_type::copy:		return false;
		case ex_type::ret:		return false;
		case ex_type::loop:		return false;
		default:				return true;
	}
}

int goparse(const char *_inputname)
{
	std::string filename = _inputname;
	std::ifstream f(filename);
	std::string buffer(std::istreambuf_iterator<char>(f), {});

	lexcontext ctx;
	ctx.cursor = buffer.c_str();
	ctx.loc.begin.filename = &filename;
	ctx.loc.end.filename = &filename;

	yy::conj_parser parser(ctx);
	parser.parse();

	std::vector<function> func_list = std::move(ctx.func_list);

	return 0;
}
