/* ==========================================================================
   Projeto: SIGAALang — Analisador Sintático
   Arquivo: parser.y
   ========================================================================== */
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* --- ESTRUTURAS DE DADOS DA ÁRVORE --- */

typedef struct Node {
    char *tipo;
    char *valor;
    struct Node *filhos[8];
    int num_filhos;
    struct Node *proximo;
} Node;

Node* criar_no(char* tipo, char* valor);
void adicionar_filho(Node* pai, Node* filho);
void imprimir_arvore(Node* raiz, int nivel);

int yylex(void);
void yyerror(const char *s);

%}

/* --- DEFINIÇÕES DO BISON --- */

%union {
    struct Node* node;
}

/* TOKENS */
%token <node> MATRICULA_ADIADA TRANCAMENTO_ADIADO
%token <node> VETOR NA_POSICAO
%token <node> EH
%token <node> SOMADO_COM SUBTRAIDO_POR MULTIPLICADO_POR DIVIDIDO_POR
%token <node> MAIOR_QUE MENOR_QUE IGUAL_A DIFERENTE_DE MAIOR_OU_IGUAL_A MENOR_OU_IGUAL_A
%token <node> TEMPORARIAMENTE_INDISPONIVEL TENTE_NOVAMENTE_MAIS_TARDE
%token <node> CAOS_GENERALIZADO
%token <node> INCONSISTENCIA_DE_DADOS DESESPERO_ESTUDANTIL ERRO_NA_ALOCACAO
%token <node> ID INT REAL
%token <node> LPAREN RPAREN LBRACE RBRACE LBRACK RBRACK SEMI VIRGULA

%type <node> programa lista_comandos comando declaracao atribuicao expressao termo fator
%type <node> lista_valores lista_parametros parametro_unico lista_argumentos tipo_retorno

%left SOMADO_COM SUBTRAIDO_POR
%left MULTIPLICADO_POR DIVIDIDO_POR

%%

/* --- REGRAS GRAMATICAIS --- */

programa:
    lista_comandos {
        Node* raiz = criar_no("program", NULL);
        adicionar_filho(raiz, $1);
        imprimir_arvore(raiz, 0);
    }
;

/* LISTA DE COMANDOS */
lista_comandos:
      comando lista_comandos { $1->proximo = $2; $$ = $1; }
    | comando                { $$ = $1; }
;

/* COMANDOS POSSÍVEIS */
comando:
      declaracao { $$ = $1; }
    | atribuicao { $$ = $1; }

    /* IF */
    | TEMPORARIAMENTE_INDISPONIVEL LPAREN expressao RPAREN
        LBRACE lista_comandos RBRACE {
            Node* n = criar_no("if", NULL);
            adicionar_filho(n, $3);
            adicionar_filho(n, $6);
            $$ = n;
        }

    | TEMPORARIAMENTE_INDISPONIVEL LPAREN expressao RPAREN
        LBRACE lista_comandos RBRACE
        TENTE_NOVAMENTE_MAIS_TARDE
        LBRACE lista_comandos RBRACE {
            Node* n = criar_no("if_else", NULL);
            adicionar_filho(n, $3);
            adicionar_filho(n, $6);
            adicionar_filho(n, $10);
            $$ = n;
        }

    /* WHILE */
    | CAOS_GENERALIZADO LPAREN expressao RPAREN LBRACE lista_comandos RBRACE {
            Node* w = criar_no("while", NULL);
            adicionar_filho(w, $3);
            adicionar_filho(w, $6);
            $$ = w;
        }

    /* FUNÇÃO */
    | INCONSISTENCIA_DE_DADOS tipo_retorno ID
        LPAREN lista_parametros RPAREN
        LBRACE lista_comandos RBRACE {
            Node* f = criar_no("function_def", NULL);
            adicionar_filho(f, $2);
            adicionar_filho(f, $3);
            adicionar_filho(f, $5);
            adicionar_filho(f, $8);
            $$ = f;
        }

    /* RETORNO */
    | DESESPERO_ESTUDANTIL expressao SEMI {
            Node* r = criar_no("return", NULL);
            adicionar_filho(r, $2);
            $$ = r;
        }
;

/* TIPOS DE RETORNO */
tipo_retorno:
      MATRICULA_ADIADA     { $$ = criar_no("return_type", "MATRICULA_ADIADA"); }
    | TRANCAMENTO_ADIADO   { $$ = criar_no("return_type", "TRANCAMENTO_ADIADO"); }
    | ERRO_NA_ALOCACAO     { $$ = criar_no("return_type", "ERRO_NA_ALOCACAO"); }
;

/* PARÂMETROS DE FUNÇÃO */
lista_parametros:
      /* vazio */          { $$ = criar_no("params", NULL); }
    | parametro_unico       { Node* p = criar_no("params", NULL); adicionar_filho(p,$1); $$ = p; }
    | lista_parametros VIRGULA parametro_unico {
          adicionar_filho($1, $3);
          $$ = $1;
      }
;

parametro_unico:
      MATRICULA_ADIADA ID {
          Node* p = criar_no("param", NULL);
          adicionar_filho(p, criar_no("type", "MATRICULA_ADIADA"));
          adicionar_filho(p, $2);
          $$ = p;
      }
    | TRANCAMENTO_ADIADO ID {
          Node* p = criar_no("param", NULL);
          adicionar_filho(p, criar_no("type", "TRANCAMENTO_ADIADO"));
          adicionar_filho(p, $2);
          $$ = p;
      }
;

/* DECLARAÇÕES */

declaracao:
    MATRICULA_ADIADA ID SEMI {
        Node* decl = criar_no("declaration", NULL);
        adicionar_filho(decl, criar_no("type", "MATRICULA_ADIADA"));
        adicionar_filho(decl, $2);
        $$ = decl;
    }

    | VETOR MATRICULA_ADIADA ID EH LBRACK lista_valores RBRACK SEMI {
        Node* d = criar_no("vector_decl", NULL);
        adicionar_filho(d, criar_no("type", "VETOR MATRICULA_ADIADA"));
        adicionar_filho(d, $3);
        adicionar_filho(d, $6);
        $$ = d;
    }
;

/* LISTA DE VALORES DE VETOR */

lista_valores:
      expressao {
          Node* l = criar_no("list", NULL);
          adicionar_filho(l, $1);
          $$ = l;
      }
    | lista_valores VIRGULA expressao {
          adicionar_filho($1, $3);
          $$ = $1;
      }
;

/* ATRIBUIÇÕES */

atribuicao:
      ID EH expressao SEMI {
            Node* a = criar_no("attribution", NULL);
            adicionar_filho(a, $1);
            adicionar_filho(a, $3);
            $$ = a;
      }

    | ID NA_POSICAO expressao EH expressao SEMI {
            Node* a = criar_no("vector_attribution", NULL);
            adicionar_filho(a, $1);
            adicionar_filho(a, $3);
            adicionar_filho(a, $5);
            $$ = a;
      }
;

/* EXPRESSÕES */

expressao:
      expressao SOMADO_COM termo {
            Node* op = criar_no("op", "+"); adicionar_filho(op,$1); adicionar_filho(op,$3); $$ = op;
      }
    | expressao SUBTRAIDO_POR termo {
            Node* op = criar_no("op", "-"); adicionar_filho(op,$1); adicionar_filho(op,$3); $$ = op;
      }
    | termo { $$ = $1; }
;

termo:
      termo MULTIPLICADO_POR fator {
            Node* op = criar_no("op", "*"); adicionar_filho(op,$1); adicionar_filho(op,$3); $$ = op;
      }
    | termo DIVIDIDO_POR fator {
            Node* op = criar_no("op", "/"); adicionar_filho(op,$1); adicionar_filho(op,$3); $$ = op;
      }
    | fator { $$ = $1; }
;

fator:
      INT { $$ = $1; }
    | REAL { $$ = $1; }
    | ID { $$ = $1; }

    /* Acesso a vetor */
    | ID NA_POSICAO expressao {
            Node* n = criar_no("vector_access", NULL);
            adicionar_filho(n, $1);
            adicionar_filho(n, $3);
            $$ = n;
      }

    /* Chamada de função */
    | ID LPAREN lista_argumentos RPAREN {
            Node* call = criar_no("call", NULL);
            adicionar_filho(call, $1);
            adicionar_filho(call, $3);
            $$ = call;
      }

    | LPAREN expressao RPAREN { $$ = $2; }
;

/* ARGUMENTOS DE FUNÇÃO */
lista_argumentos:
      /* vazio */ { $$ = criar_no("args", NULL); }
    | expressao {
          Node* a = criar_no("args", NULL);
          adicionar_filho(a, $1);
          $$ = a;
      }
    | lista_argumentos VIRGULA expressao {
          adicionar_filho($1, $3);
          $$ = $1;
      }
;

%%

/* ------ IMPLEMENTAÇÃO DOS NÓS ------ */

Node* criar_no(char* tipo, char* valor) {
    Node* n = malloc(sizeof(Node));
    n->tipo = strdup(tipo);
    n->valor = valor ? strdup(valor) : NULL;
    n->num_filhos = 0;
    n->proximo = NULL;
    for(int i=0;i<8;i++) n->filhos[i] = NULL;
    return n;
}

void adicionar_filho(Node* pai, Node* filho) {
    if (pai->num_filhos < 8) pai->filhos[pai->num_filhos++] = filho;
}

void imprimir_arvore(Node* r, int nivel) {
    if (!r) return;

    for(int i=0;i<nivel;i++) printf("  ");

    if (r->valor) printf("%s\n", r->valor);
    else          printf("%s\n", r->tipo);

    for(int i=0;i<r->num_filhos;i++)
        imprimir_arvore(r->filhos[i], nivel+1);

    if (r->proximo)
        imprimir_arvore(r->proximo, nivel);
}

void yyerror(const char *s){
    printf("Erro sintático: %s\n", s);
}

int main(){ return yyparse(); }

