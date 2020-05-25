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
inline bool is_##n(const identifier& i) { return i.type == id_type::n; }
ENUM_IDENTIFIERS(o)
#undef o

#define o(n) \
inline bool is_##n(const expression& e) { return e.type == ex_type::n; } \
template<typename... T> \
inline expression e_##n(T&&... args) { return expression(ex_type::n, std::forward<T>(args)...); }
ENUM_EXPRESSIONS(o)
#undef o

struct function
{
	std::string name;
	expression code;
	unsigned num_vars = 0, num_params = 0;
	bool pure = false, pure_known = false;

	expression maketemp() { expression r(identifier{id_type::variable, num_vars, "$C" + std::to_string(num_vars)}); ++num_vars; return r; }
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
%type<std::string>	IDENTIFIER STRINGCONST identifier1
%type<expression>	expr expr1 exprs exprs1 c_expr1 p_expr1 stmt stmt1 var_defs var_def1 com_stmt

%%

library:										{ ++ctx; } functions { --ctx; };
functions:										functions identifier1 { ctx.defun($2); ++ctx; } paramdecls colon1 stmt1 { ctx.add_function(M($2), M($6)); --ctx; }
|												%empty;
paramdecls:										paramdecl | %empty;
paramdecl:										paramdecl ',' identifier1	{ ctx.defparm($3); }
|												IDENTIFIER					{ ctx.defparm($1); };
identifier1:		error {}			|		IDENTIFIER					{ $$ = M($1); };
colon1:				error {}			|		':';
semicolon1:			error {}			|		';';
cl_brace1:			error {}			|		'}';
cl_bracket1:		error {}			|		']';
cl_parens1:			error {}			|		')';
stmt1:				error {}			|		stmt						{ $$ = M($1); };
exprs1:				error {}			|		exprs						{ $$ = M($1); };
expr1:				error {}			|		expr						{ $$ = M($1); };
p_expr1:			error {}			|		'(' exprs1 cl_parens1		{ $$ = M($2); };
stmt:											com_stmt cl_brace1			{ $$ = M($1); --ctx; }
|												"if" p_expr1 stmt1			{ $$ = e_cand(M($2), M($3)); }
|												"while" p_expr1 stmt1		{ $$ = e_loop(M($2), M($3)); }
|												"return" exprs1 semicolon1	{ $$ = e_ret(M($2)); }
|												exprs semicolon1			{ $$ = M($1); }
|												';'							{ };
com_stmt:										'{'							{ $$ = e_comma(); ++ctx; }
|												com_stmt stmt				{ $$ = M($1); $$.params.push_back(M($2)); };
var_defs:										"var" var_def1				{ $$ = e_comma(M($2)); }
|												var_defs ',' var_def1		{ $$ = M($1); $$.params.push_back(M($3)); };
var_def1:										identifier1 '=' expr1		{ $$ = ctx.def($1) %= M($3); }
|												identifier1					{ $$ = ctx.def($1) %= 0L; };
exprs:											var_defs					{ $$ = M($1); }
|												expr						{ $$ = M($1); }
|												expr ',' c_expr1			{ $$ = e_comma(M($1)); $$.params.splice($$.params.end(), M($3.params)); };
c_expr1:										expr1						{ $$ = e_comma(M($1)); }
|												c_expr1 ',' expr1			{ $$ = M($1); $$.params.push_back(M($3)); };
expr:											NUMCONST					{ $$ = $1; }
|												STRINGCONST					{ $$ = M($1); }
|												IDENTIFIER					{ $$ = ctx.use($1); }
|												'(' expr cl_parens1			{ $$ = M($2); }
|												expr '[' exprs1 cl_bracket1	{ $$ = e_deref(e_add(M($1), M($3))); }
|												expr '(' ')'				{ $$ = e_fcall(M($1)); }
|												expr '(' c_expr1 cl_parens1	{ $$ = e_fcall(M($1)); $$.params.splice($$.params.end(), M($3.params)); }
|	expr '=' error {$$=M($1);}			|		expr '=' expr				{ $$ = M($1) %= M($3); }
|	expr '+' error {$$=M($1);}			|		expr '+' expr				{ $$ = e_add(M($1), M($3)); }
|	expr '-' error {$$=M($1);}			|		expr '-' expr %prec '+'		{ $$ = e_add(M($1), e_neg(M($3))); }
|	expr "+=" error {$$=M($1);}			|		expr "+=" expr				{ if(!$3.is_pure()) { $$ = ctx.temp() %= e_addrof(M($1)); $1 = e_deref($$.params.back()); }
																			  $$ = e_comma(M($$), M($1) %= e_add(C($1), M($3))); }
|	expr "-=" error {$$=M($1);}			|		expr "-=" expr				{ if(!$3.is_pure()) { $$ = ctx.temp() %= e_addrof(M($1)); $1 = e_deref($$.params.back()); }
																			  $$ = e_comma(M($$), M($1) %= e_add(C($1), e_neg(M($3)))); }
|	"++" error {}						|		"++" expr					{ if(!$2.is_pure()) { $$ = ctx.temp() %= e_addrof(M($2)); $2 = e_deref($$.params.back()); }
																			  $$ = e_comma(M($$), M($2) %= e_add(C($2), 1L)); }
|	"--" error {}						|		"--" expr %prec "++"		{ if(!$2.is_pure()) { $$ = ctx.temp() %= e_addrof(M($2)); $2 = e_deref($$.params.back()); }
																			  $$ = e_comma(M($$), M($2) %= e_add(C($2), -1L)); }
|												expr "++"					{ if(!$1.is_pure()) { $$ = ctx.temp() %= e_addrof(M($1)); $1 = e_deref($$.params.back()); }
																			  auto i = ctx.temp(); $$ = e_comma(M($$), C(i) %= C($1), C($1) %= e_add(C($1), 1L), C(i)); }
|												expr "--" %prec "++"		{ if(!$1.is_pure()) { $$ = ctx.temp() %= e_addrof(M($1)); $1 = e_deref($$.params.back()); }
																			  auto i = ctx.temp(); $$ = e_comma(M($$), C(i) %= C($1), C($1) %= e_add(C($1), -1L), C(i)); }
|	expr "||" error {$$=M($1);}			|		expr "||" expr				{ $$ = e_cor(M($1), M($3)); }
|	expr "&&" error {$$=M($1);}			|		expr "&&" expr				{ $$ = e_cand(M($1), M($3)); }
|	expr "==" error {$$=M($1);}			|		expr "==" expr				{ $$ = e_eq(M($1), M($3)); }
|	expr "!=" error {$$=M($1);}			|		expr "!=" expr %prec "=="	{ $$ = e_eq(e_eq(M($1), M($3)), 0L); }
|	'&' error {}						|		'&' expr					{ $$ = e_addrof(M($2)); }
|	'*' error {}						|		'*' expr %prec '&'			{ $$ = e_deref(M($2)); }
|	'-' error {}						|		'-' expr %prec '&'			{ $$ = e_neg(M($2)); }
|	'!' error {}						|		'!' expr %prec '&'			{ $$ = e_eq(M($2), 0L); }
|	expr '?' error {$$=M($1);}			|		expr '?' expr ':' expr		{ auto i = ctx.temp();
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
#include <memory>
#include <unordered_map>
#include <functional>
#include <numeric>
#include <set>

/* Global Data */
std::vector<function> func_list;

static bool pure_fcall(const expression& exp)
{
	if(const auto& p = exp.params.front(); is_ident(p) && is_function(p.ident))
		if(auto called_function = p.ident.index; called_function < func_list.size())
			if (const auto& f = func_list[called_function]; f.pure_known && f.pure)
				return true;
	return false;
}

bool expression::is_pure() const
{
	for(const auto& e : params) if (!e.is_pure()) return false;
	switch(type)
	{
		case ex_type::fcall:	return pure_fcall(*this);
		case ex_type::copy:		return false;
		case ex_type::ret:		return false;
		case ex_type::loop:		return false;
		default:				return true;
	}
}

template<typename F, typename B, typename... A>
static decltype(auto) callv(F&& func, B&& def, A&&... args)
{
	if constexpr(std::is_invocable_r_v<B,F,A...>)
	{
		return std::forward<F>(func)(std::forward<A>(args)...);
	}
	else
	{
		static_assert(std::is_void_v<std::invoke_result_t<F,A...>>);
		std::forward<F>(func)(std::forward<A>(args)...);
		return std::forward<B>(def);
	}
}

template<typename E, typename... F>
static bool for_all_expr(E& p, bool inclusive, F&&... funcs)
{
	static_assert(std::conjunction_v<std::is_invocable<F, expression&>...>);
	return std::any_of(p.params.begin(), p.params.end(), [&](E& e) { return for_all_expr(e, true, funcs...); })
		|| (inclusive && ... && callv(funcs, false, p));
}

static void findpurefunctions()
{
	for (auto& f : func_list) f.pure_known = f.pure = false;
	do { } while(std::count_if(func_list.begin(), func_list.end(), [&](function& f)
	{
		if (f.pure_known) return false;
		std::cerr << "Identifying " << f.name << "\n";
		bool unknown_functions = false;
		bool side_effects = for_all_expr(f.code, true, [&](const expression& exp)
		{
			if (is_copy(exp)) { return for_all_expr(exp.params.back(), true, is_deref); }
			if (is_fcall(exp))
			{
				const auto& e = exp.params.front();
				if (is_ident(e) || !is_function(e.ident)) return true;
				const auto& u = func_list[e.ident.index];
				if (u.pure_known && !u.pure) return true;
				if (!u.pure_known && e.ident.index != (&f - &func_list[0])) // Recursions ignored
				{
					std::cerr << "Function " << f.name << " calls unknown function " << u.name << "\n";
					unknown_functions = true;
				}
			}
			return false;
		});
		for (auto& f : func_list)
			if (!f.pure_known)
				std::cerr << "Could not figure out whether " << f.name << " is a pure function\n";
		if (side_effects || !unknown_functions)
		{
			f.pure_known = true;
			f.pure = !side_effects;
			std::cerr << "Function " << f.name << (f.pure ? " is pure\n" : " may have side-effects\n");
			return true;
		}
		return false;
	}));
}

std::string stringify(const expression& e, bool stmt);
std::string stringify_op(const expression& e, const char *sep, const char *delim, bool stmt = false, unsigned first=0, unsigned limit=~0U)
{
	std::string result(1, delim[0]);
	const char *fsep = "";
	for(const auto& p : e.params) {
		if(first) { --first; continue; }
		if(!limit--) break;
		result += fsep; fsep = sep; result += stringify(p, stmt);
	}
	if (stmt) result += sep; 
	result += delim[1];
	return result;
}
std::string stringify(const expression& e, bool stmt = false)
{
	auto expect1 = [&]{ return e.params.empty() ? "?" : e.params.size()==1 ? stringify(e.params.front()) : stringify_op(e, "??", "()"); };
	switch (e.type)
	{
		// Atoms
		case ex_type::nop:				return "";
		case ex_type::string:			return "\"" + e.strvalue + "\"";
		case ex_type::number:			return std::to_string(e.numvalue);
		case ex_type::ident:			return "?FPVS"[(int)e.ident.type] + std::to_string(e.ident.index) + "\"" + e.ident.name + "\"";
		// Binary & misc
		case ex_type::add:				return stringify_op(e, " + ",  "()");
		case ex_type::eq:				return stringify_op(e, " == ", "()");
		case ex_type::cand:				return stringify_op(e, " && ", "()");
		case ex_type::cor:				return stringify_op(e, " || ", "()");
		case ex_type::comma:			return stmt ? stringify_op(e, "; ", "{}", true) : stringify_op(e, ", ", "()");
		// Unary
		case ex_type::neg:				return "-(" + expect1() + ")";
		case ex_type::deref:			return "*(" + expect1() + ")";
		case ex_type::addrof:			return "&(" + expect1() + ")";
		// Special
		case ex_type::copy:				return "(" + stringify(e.params.back()) + " = " + stringify(e.params.front()) + ")";
		case ex_type::fcall:			return "(" + (e.params.empty() ? "?" : stringify(e.params.front())) + ")" + stringify_op(e, ", ", "()", false, 1);
		case ex_type::loop:				return "white " + stringify(e.params.front()) + " " + stringify_op(e, "; ", "{}", true, 1);
		case ex_type::ret:				return "return " + expect1();
	}

	return "?";
}

static std::string stringify(const function& f)
{
	return stringify(f.code, true);
}

#include "textbox.hpp"

static std::string stringify_tree(const function& f)
{
	textbox result;
	result.putbox(2,0,create_tree_graph(f.code, 200-2,
		[](const expression& e)
		{
			std::string p = stringify(e), k = p;
			switch(e.type)
			{
				#define o(n) case ex_type::n: k.assign(#n,sizeof(#n)-1); break;
				ENUM_EXPRESSIONS(o)
				#undef o
			}
			return e.params.empty() ? (k + " " + p) : std::move(k);
		},
		[](const expression& e) { return std::make_pair(e.params.cbegin(), e.params.cend()); },
		[](const expression& e) { return e.params.size() >= 1; },
		[](const expression&  ) { return true; },
		[](const expression& e) { return e.type == ex_type::loop; }));
	return "function " + f.name + ":\n" + stringify(f) + "\n" + result.to_string();
}

static bool equal(const expression& a, const expression& b)
{
	return (a.type == b.type) &&
		(!is_ident(a) || (a.ident.type == b.ident.type && a.ident.index == b.ident.index)) &&
		(!is_string(a) || a.strvalue == b.strvalue ) &&
		(!is_number(a) || a.numvalue == b.numvalue ) &&
		std::equal(a.params.begin(), a.params.end(), b.params.begin(), b.params.end(), equal);
}

static void constantfolding(expression& e, function& f)
{
	// Adopt all parameters of the same type
	if (is_add(e) || is_comma(e) || is_cor(e) || is_cand(e))
	{
		for (auto j=e.params.end(); j!=e.params.begin(); )
			if((--j)->type == e.type)
			{
				auto tmp(M(j->params));
				e.params.splice(j=e.params.erase(j), std::move(tmp));
			}
	}

	// if copy (assign) is parameter for an expression (except command and addrof) then use a temp to hold the value of assign and distribute from there
	if (!is_comma(e) && !is_addrof(e) && !e.params.empty())
		for (auto i=e.params.begin(), j = (is_loop(e) ? std::next(i) : e.params.end()); i!=j; ++i)
			if (is_copy(*i))
			{
				auto assign = M(*i); *i = e_comma();
				if(assign.params.front().is_pure())
				{
					i->params.push_back(C(assign.params.front()));
					i->params.push_front(M(assign));
				}
				else
				{
					expression temp = f.maketemp();
					i->params.push_back(C(temp) %= M(assign.params.front()));
					i->params.push_back(M(assign.params.back()) %= C(temp));
					i->params.push_back(M(temp));
				}
			}

	if (std::find_if(e.params.begin(), e.params.end(), is_comma) != e.params.end())
	{
		auto end = (is_cand(e) || is_cor(e) || is_loop(e)) ? std::next(e.params.begin()) : e.params.end();
		for(;end!=e.params.begin();--end)
		{
			auto prev = std::prev(end);
			if(is_comma(*prev) && prev->params.size() > 1) break;
		}
		expr_vec comma_params;
		for (expr_vec::iterator i=e.params.begin(); i!=end; ++i)
		{
			if (is_comma(*i) && i->params.size() > 1)
				comma_params.splice(comma_params.end(), i->params, i->params.begin(), std::prev(i->params.end()));
		}
		if (comma_params.empty())
		{
			comma_params.push_back(M(e));
			e = e_comma(M(comma_params));
		}
	}

	switch(e.type)
	{
		// Collapse addition of series of integer literals to a single literal, ignore zero sum
		case ex_type::add:
		{
			long tmp = std::accumulate(e.params.begin(), e.params.end(), 0L,
				[](long n, auto& p) { return is_number(p) ? n+p.numvalue : n; });
			e.params.remove_if(is_number);
			// Adopt all negated adds
			for(auto j=e.params.begin(); j!=e.params.end(); ++j)
				if (is_neg(*j) && is_add(j->params.front()))
				{
					auto tmp(std::move(j->params.front().params));
					for (auto& p : tmp) p = e_neg(M(p));
					e.params.splice(j=e.params.erase(j), std::move(tmp));
				}
			if (tmp!=0) e.params.push_back(tmp);
			if (std::count_if(e.params.begin(), e.params.end(), is_neg) > long(e.params.size()/2))
			{
				for(auto& p : e.params) p = e_neg(M(p));
				e = e_neg(M(e));
			}
		}
		break;
		// Replace negated integer constant with actual negative counterpart
		case ex_type::neg:
			if (is_number(e.params.front())) e = -e.params.front().numvalue;
			else if(is_neg(e.params.front())) e = C(M(e.params.front().params.front()));
		break;
		// Drop integer-to-integer compares and replace with result of compare
		case ex_type::eq:
			if (is_number(e.params.front()) && is_number(e.params.back()))
				e = long(e.params.front().numvalue == e.params.back().numvalue);
			else if (equal(e.params.front(), e.params.back()) && e.params.front().is_pure())
				e = 1L;
		break;
		// Reduce *&x to x
		case ex_type::deref:
			if (is_addrof(e.params.front())) e = C(M(e.params.front().params.front()));
		break;
		// Reduce &* to x
		case ex_type::addrof:
			if (is_deref(e.params.front())) e = C(M(e.params.front().params.front()));
		break;
		// If an integer literal is found in a series of && or ||, remove the rest of logic accordingly
		case ex_type::cand:
		case ex_type::cor:
		{
			auto value_kind = is_cand(e) ? [](long v) { return v!=0; } : [](long v) { return v==0; };
			e.params.erase(std::remove_if(e.params.begin(), e.params.end(),
							[&](expression& p) { return is_number(p) && value_kind(p.numvalue); }),
						e.params.end());
			if (auto i = std::find_if(e.params.begin(), e.params.end(),
							[&](const expression& p) { return is_number(p) && !value_kind(p.numvalue); });
						i != e.params.end())
			{
				while(i!=e.params.begin() && std::prev(i)->is_pure()) { --i; }
				// Remove everything after and replace with a comma statement that produces 0(for &&) or 1(for ||)
				e.params.erase(i, e.params.end());
				e = e_comma(M(e), is_cand(e) ? 0L : 1L);
			}
		}
		break;
		// Drop x=x (self assignment)
		case ex_type::copy:
			if (equal(e.params.front(), e.params.back()) && e.params.front().is_pure())
				e = C(M(e.params.back()));
		break;
		// Drop zero-count loops (with loop counter as literal)
		case ex_type::loop:
			if(is_number(e.params.front()) && !e.params.front().numvalue) { e = e_nop(); break; }
			[[fallthrough]];
		// Remove all params following a return statement or following an infinite loop
		case ex_type::comma:
			for (auto i=e.params.begin(); i!=e.params.end(); )
			{
				if(is_loop(e))
					{ if(i==e.params.begin()) {++i; continue; } }
				else
					{ if (std::next(i) == e.params.end()) break; }
				if (i->is_pure())
				{
					i = e.params.erase(i);
				}
				else switch(i->type)
				{
					default:
						++i;
					break;
					case ex_type::fcall:
						if(!pure_fcall(e)) { ++i; break; }
						[[fallthrough]];
					case ex_type::add:
					case ex_type::neg:
					case ex_type::eq:
					case ex_type::addrof:
					case ex_type::deref:
					case ex_type::comma:
						auto tmp(std::move(i->params));
						e.params.splice(i=e.params.erase(i), std::move(tmp));
				}
			}
			if (auto r = std::find_if(e.params.begin(), e.params.end(),
				[](const expression& e){ return is_ret(e) || (is_loop(e) && is_number(e.params.front()) && e.params.front().numvalue != 0); });
				r != e.params.end() && ++r != e.params.end())
			{
				std::cerr << std::distance(r, e.params.end()) << " dead expression deleted\n";
				e.params.erase(r, e.params.end());
			}
			// Remove cases such as x=(a=3, a)
			if (e.params.size() == 2)
			{
				auto& last = e.params.back();
				auto& prev = *std::next(e.params.rbegin());
				if (is_copy(prev) && equal(prev.params.back(), last))
					e.params.pop_back();
			}
			// Nothing much left, replace with param
			if (e.params.size() == 1 && !is_loop(e))
				e = C(M(e.params.front()));
		break;
		default:
		break;
	}

	switch (e.params.size())
	{
		case 1:
			if (is_add(e)) e = C(M(e.params.front()));
			else if (is_cor(e) || is_cand(e)) e = e_eq(e_eq(M(e.params.front()), 0L), 0L); // bool-cast
			break;
		case 0:
			if (is_add(e) || is_cor(e)) e = 0L;
			else if(is_cand(e)) e = 1L;
			break;
	}
}

static void doconstantfolding()
{
	findpurefunctions();
	/*for (function& f : func_list)
	{
		for_all_expr(f.code, true, [&](expression& e) { constantfolding(e,f); });
	}*/
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

	func_list = std::move(ctx.func_list);

	// pre-optimization
	std::cout << "Initial\n";
	for (const auto& f : func_list) std::cerr << stringify_tree(f);

	doconstantfolding();

	// post-optimization
	std::cout << "Final\n";
	for (const auto& f : func_list) std::cerr << stringify_tree(f);

	return 0;
}
