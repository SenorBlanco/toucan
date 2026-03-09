/* Copyright 2023 The Toucan Authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

%{
#include <stdlib.h>
#include <string.h>
#include <unordered_map>
#include <string>

#include "parser/lexer.h"
#include "ast/type.h"

#include "parser.tab.hh"

using namespace Toucan;

extern Type* FindType(const char* str);

std::unordered_map<std::string, std::string> identifiers_;

#define YY_NEVER_INTERACTIVE 1

// This should fix the unistd.h problem on Windows, except that YY_NO_UNISTD_H
// is only valid in flex 2.5.6 and up.  :(
#ifdef _WIN32
#define YY_NO_UNISTD_H 1
#define isatty(t) 0
#endif

namespace {

long readUInt(const char* text, int base) {
  errno = 0;
  long val = std::strtoul(yytext, nullptr, base);
  if (errno == ERANGE) {
    yyerror("integer literal is out of range");
  }
  return val;
}

}

%}

ALPHA           [a-zA-Z_]
ALPHANUM        [a-zA-Z0-9_]
EXPONENT        ([Ee]("-"|"+")?[0-9]+)

%x include

%%

([0-9]+"."[0-9]+|[0-9]*"."[0-9]+){EXPONENT}? { yylval.f = std::strtof(yytext, nullptr); return T_FLOAT_LITERAL; }

([0-9]+"."[0-9]+|[0-9]*"."[0-9]+){EXPONENT}?d { yylval.d = std::strtod(yytext, nullptr); return T_DOUBLE_LITERAL; }

[0-9]+{EXPONENT}      { yylval.f = std::strtof(yytext, nullptr); return T_FLOAT_LITERAL; }

[0-9]+{EXPONENT}d     { yylval.d = std::strtod(yytext, nullptr); return T_DOUBLE_LITERAL; }

0x[0-9a-fA-F]+        { yylval.i = readUInt(yytext, 16); return T_INT_LITERAL; }

[0-9]+b               { yylval.i = readUInt(yytext, 10); return T_BYTE_LITERAL; }

[0-9]+ub              { yylval.i = readUInt(yytext, 10); return T_UBYTE_LITERAL; }

[0-9]+s               { yylval.i = readUInt(yytext, 10); return T_SHORT_LITERAL; }

[0-9]+us              { yylval.i = readUInt(yytext, 10); return T_USHORT_LITERAL; }

[0-9]+                { yylval.i = readUInt(yytext, 10); return T_INT_LITERAL; }

[0-9]+u               { yylval.i = readUInt(yytext, 10); return T_UINT_LITERAL; }

as      { return T_AS; }
var     { return T_VAR; }
const   { return T_CONST; }
false   { return T_FALSE; }
null    { return T_NULL; }
true    { return T_TRUE; }
if      { return T_IF; }
else    { return T_ELSE; }
for     { return T_FOR; }
while   { return T_WHILE; }
do      { return T_DO; }
return  { return T_RETURN; }
new     { return T_NEW; }
class   { return T_CLASS; }
enum    { return T_ENUM; }
static  { return T_STATIC; }
vertex  { return T_VERTEX; }
index   { return T_INDEX; }
fragment { return T_FRAGMENT; }
compute { return T_COMPUTE; }
uniform { return T_UNIFORM; }
storage { return T_STORAGE; }
sampleable { return T_SAMPLEABLE; }
renderable { return T_RENDERABLE; }
this    { return T_THIS; }
readonly { return T_READONLY; }
writeonly { return T_WRITEONLY; }
deviceonly { return T_DEVICEONLY; }
coherent { return T_COHERENT; }
hostreadable { return T_HOSTREADABLE; }
hostwriteable { return T_HOSTWRITEABLE; }
using   { return T_USING; }
inline  { return T_INLINE; }
unfilterable { return T_UNFILTERABLE; }
include BEGIN(include);

int     { return T_INT; }
uint    { return T_UINT; }
float   { return T_FLOAT; }
double  { return T_DOUBLE; }
bool    { return T_BOOL; }
byte    { return T_BYTE; }
ubyte   { return T_UBYTE; }
short   { return T_SHORT; }
ushort  { return T_USHORT; }
half    { return T_HALF; }

{ALPHA}{ALPHANUM}* {
  identifiers_[yytext] = yytext;
  yylval.identifier = identifiers_[yytext].c_str();
  return T_IDENTIFIER;
}

\"([^\"]|\\\"|\\\\)*\" {
  for (const char *s = yytext; *s; s++) {
    if (*s == '\n') IncLineNum();
  }
  std::string s(yytext + 1, strlen(yytext) - 2);
  identifiers_[yytext] = s;
  yylval.identifier = identifiers_[yytext].c_str();
  return T_STRING_LITERAL;
}

[ \t\r]+        /* eat up whitespace */
\/\/.*\n        { IncLineNum(); }

\n              { IncLineNum(); }

\<              { return T_LT; }
\<=             { return T_LE; }
==              { return T_EQ; }
\>=             { return T_GE; }
\>              { return T_GT; }
!=              { return T_NE; }

\+=             { return T_ADD_EQUALS; }
-=              { return T_SUB_EQUALS; }
\*=             { return T_MUL_EQUALS; }
\/=             { return T_DIV_EQUALS; }

&&              { return T_LOGICAL_AND; }
\|\|            { return T_LOGICAL_OR; }

\+\+            { return T_PLUSPLUS; }
--              { return T_MINUSMINUS; }
\.\.            { return T_DOTDOT; }

.               { return yytext[0]; }

<include>[ \t\n]+  /* eat the whitespace */
<include>[^ \t\n]+ {
    std::string filename(yytext + 1, strlen(yytext) - 2);
    FILE* f = IncludeFile(filename.c_str());
    if (f) {
        yyin = f;
        yypush_buffer_state(yy_create_buffer(yyin, YY_BUF_SIZE));
    }
    BEGIN(INITIAL);
}

<<EOF>> {
    if (yy_buffer_stack_top > 0) {
        yypop_buffer_state();
        PopFile();
    } else {
        return 0;
    }
}

%%

struct Token {
  int token;
  YYSTYPE value;
};

using TokenVector = std::vector<Token>;

struct Macro {
  TokenVector tokens;
};

std::unordered_map<std::string, Macro> macros_;
Macro* currentMacro_;
TokenVector::iterator currentToken_;

static int get_next_token() {
  if (currentMacro_) {
    if (currentToken_ != currentMacro_->tokens.end()) {
      int token = currentToken_->token;
      yylval = currentToken_->value;
      currentToken_++;
      return token;
    }
    currentMacro_ = nullptr;
  }
  return yylex();
}

static int record_next_token(Macro& macro) {
  int token = get_next_token();
  if (token != 0) macro.tokens.push_back(Token({token, yylval}));
  return token;
}

static void define(Macro& macro) {
  int token = 0;
  do {
    token = record_next_token(macro);
    if (token == '#') {
      int token = record_next_token(macro);
      if (token == T_IDENTIFIER) {
        if (!strcmp(yylval.identifier, "enddef")) {
          return;
        } else if (!strcmp(yylval.identifier, "def")) {
          define(macro);
        } else {
          yyerror("invalid directive");
        }
      }
    }
  } while (token != 0);
  yyerror("missing #enddef");
}

static void directive() {
  int token = get_next_token();
  if (token != T_IDENTIFIER) {
    yyerror("invalid directive");
  } else if (!strcmp(yylval.identifier, "def")) {
    token = get_next_token();
    if (token != T_IDENTIFIER) {
      yyerror("invalid macro name");
    } else {
      Macro& macro = macros_[yylval.identifier];
      define(macro);
      if (macro.tokens.size() >= 2) {
        macro.tokens.resize(macro.tokens.size() - 2);
      }
    }
  } else {
    yyerror("invalid directive");
  }
}

int lex() {
  int token = get_next_token();
  if (token == '#') {
    directive();
    return lex();
  } else if (token == T_IDENTIFIER) {
    auto it = macros_.find(yylval.identifier);
    if (it != macros_.end()) {
      currentMacro_ = &it->second;
      currentToken_ = currentMacro_->tokens.begin();
      return lex();
    } else if (Type* t = FindType(yylval.identifier)) {
      yylval.type = t;
      return T_TYPENAME;
    }
  }
  return token;
}

void lex_destroy() {
#ifndef _WIN32
    yylex_destroy();
#endif
}
