%skeleton "lalr1.cc"
%define api.parser.class {elang_parser}
%define api.token.constructor
%define api.value.type variant
%define parse.assert
%define parse.error verbose
%locations

%code requires
{
	#include <algorithm>

struct LexerContext;

}//%code requires

%param { LexerContext& ctx }//%param

%code
{

struct LexerContext
{
    const char* cursor;
    yy::location loc;
};

namespace yy { elang_parser::symbol_type yylex(LexerContext& ctx); }

}//%code

%token             END 0
%token             NOOP "noop"
%%

library: noop | %empty
noop:    "noop"

%%

yy::elang_parser::symbol_type yy::yylex(LexerContext& ctx)
{
    const char* anchor = ctx.cursor;
    ctx.loc.step();

/* %{

re2c:yyfill:enable   = 0;
re2c:define:YYCTYPE  = "char";
re2c:define:YYCURSOR = "ctx.cursor";

// Keywords:
"noop"                	{ return elang_parser::make_NOOP(ctx.loc); }

%} */
	return elang_parser::make_NOOP(ctx.loc);
}

void yy::elang_parser::error(const location_type& l, const std::string& m)
{
    std::cerr << (l.begin.filename ? l.begin.filename->c_str() : "(undefined)");
    std::cerr << ':' << l.begin.line << ':' << l.begin.column << '-' << l.end.column << ": " << m << '\n';
}
