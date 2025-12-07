/* =============================================================================
   Projeto: SIGAALang — Analisador Léxico (Adaptado para Bison)
   Arquivo: lexer.l
   ============================================================================= */
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h" /* Inclui as definições geradas pelo Bison */

/* Declaramos a função 'criar_no' como externa, pois ela está implementada 
   no arquivo parser.y (ou parser.tab.c após compilado).
*/
extern void* criar_no(char* tipo, char* valor);

/* Posição atual no código-fonte */
int linha = 1;
int coluna = 1;

void atualiza_pos(const char *text) {
    for (int i = 0; text[i] != '\0'; i++) {
        if (text[i] == '\n') { 
            linha++;
            coluna = 1; 
        } else { 
            coluna++;
        }
    }
}

void err_lex(const char *msg) {
    fprintf(stderr, "Erro Lexico na linha %d, coluna %d: %s\n", linha, coluna, msg);
}

%}

%option noyywrap

/* -------------------- Definições -------------------- */
ID              [A-Za-z][A-Za-z0-9]*
INT             [0-9]+
REAL            [0-9]+\.[0-9]+([eE][+-]?[0-9]+)?
WS              [ \t\r\n]+
COMMENT         CARTA_ABERTA[^\n]*

%%

    /* --- PALAVRAS-CHAVE --- */
    /* Apenas retornamos o código do token. Não precisamos criar nó aqui, 
       o Bison vai criar os nós pais (statement, declaration, etc.) */

"MATRICULA_ADIADA"      { atualiza_pos(yytext); return MATRICULA_ADIADA; }
"TRANCAMENTO_ADIADO"    { atualiza_pos(yytext); return TRANCAMENTO_ADIADO; }
"EH"                    { atualiza_pos(yytext); return EH; }
"SOMADO_COM"            { atualiza_pos(yytext); return SOMADO_COM; }
"SUBTRAIDO_POR"         { atualiza_pos(yytext); return SUBTRAIDO_POR; }
"MULTIPLICADO_POR"      { atualiza_pos(yytext); return MULTIPLICADO_POR; }
"DIVIDIDO_POR"          { atualiza_pos(yytext); return DIVIDIDO_POR; }
"MAIOR_QUE"             { atualiza_pos(yytext); return MAIOR_QUE; }
"MENOR_QUE"             { atualiza_pos(yytext); return MENOR_QUE; }
"IGUAL_A"               { atualiza_pos(yytext); return IGUAL_A; }
"DIFERENTE_DE"          { atualiza_pos(yytext); return DIFERENTE_DE; }
"MAIOR_OU_IGUAL_A"      { atualiza_pos(yytext); return MAIOR_OU_IGUAL_A; }
"MENOR_OU_IGUAL_A"      { atualiza_pos(yytext); return MENOR_OU_IGUAL_A; }
"TEMPORARIAMENTE_INDISPONIVEL" { atualiza_pos(yytext); return TEMPORARIAMENTE_INDISPONIVEL; }
"TENTE_NOVAMENTE_MAIS_TARDE"   { atualiza_pos(yytext); return TENTE_NOVAMENTE_MAIS_TARDE; }
"CAOS_GENERALIZADO"     { atualiza_pos(yytext); return CAOS_GENERALIZADO; }
"INCONSISTENCIA_DE_DADOS" { atualiza_pos(yytext); return INCONSISTENCIA_DE_DADOS; }
"DESESPERO_ESTUDANTIL"  { atualiza_pos(yytext); return DESESPERO_ESTUDANTIL; }
"ERRO_NA_ALOCACAO"      { atualiza_pos(yytext); return ERRO_NA_ALOCACAO; }
"NA_POSICAO"            { atualiza_pos(yytext); return NA_POSICAO; }
"VETOR"                 { atualiza_pos(yytext); return VETOR; }

    /* --- LITERAIS E IDENTIFICADORES (FOLHAS DA ÁRVORE) --- */
    /* Aqui precisamos criar o nó e passar para o Bison via yylval */

{REAL} { 
    atualiza_pos(yytext);
    /* Cria um nó tipo "num" com o valor do texto (ex: "10.5") */
    yylval.node = criar_no("num", yytext);
    return REAL; 
}

{INT} { 
    atualiza_pos(yytext);
    /* Cria um nó tipo "num" com o valor do texto (ex: "10") */
    yylval.node = criar_no("num", yytext);
    return INT; 
}

{ID} { 
    atualiza_pos(yytext);
    /* Cria um nó tipo "id" com o nome da variável (ex: "nota1") */
    yylval.node = criar_no("id", yytext);
    return ID; 
}

    /* --- SÍMBOLOS E DELIMITADORES --- */

"("   { atualiza_pos(yytext); return LPAREN; }
")"   { atualiza_pos(yytext); return RPAREN; }
"["   { atualiza_pos(yytext); return LBRACK; }
"]"   { atualiza_pos(yytext); return RBRACK; }
"{"   { atualiza_pos(yytext); return LBRACE; }
"}"   { atualiza_pos(yytext); return RBRACE; }
";"   { atualiza_pos(yytext); return SEMI; }
","   { atualiza_pos(yytext); return VIRGULA; }

    /* --- IGNORADOS E ERROS --- */

{WS}       { atualiza_pos(yytext); /* Ignora espaços */ }
{COMMENT}  { atualiza_pos(yytext); /* Ignora comentários */ }

.          { 
    atualiza_pos(yytext);
    err_lex(yytext); 
}

%%
/* Nenhuma função main().A main() estará no parser.y */