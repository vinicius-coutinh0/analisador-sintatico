/* ==========================================================================
   Projeto: SIGAALang — Analisador Sintatico
   Arquivo: parser.y
   ========================================================================== */
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* --- ESTRUTURAS DE DADOS DA ÁRVORE (CÓDIGO C) --- */

typedef struct Node {
    char *tipo;           // Ex: "program", "if", "id", "num"
    char *valor;          // Ex: "nota1", "10.5", "+" (pode ser NULL para nós internos)
    struct Node *filhos[4]; // Até 4 filhos (suficiente para if-else, etc.)
    int num_filhos;
    struct Node *proximo; // Para listas encadeadas de comandos
} Node;

/* Definições das funções auxiliares */
Node* criar_no(char* tipo, char* valor);
void adicionar_filho(Node* pai, Node* filho);
void imprimir_arvore(Node* raiz, int nivel);
int yylex(void);
void yyerror(const char *s);

%}

/* --- DEFINIÇÕES DO BISON --- */

/* Definimos que o Bison pode carregar um ponteiro para Node */
%union {
    struct Node* node;
}

/* Declaração dos Tokens (Vindos do Lexer) */
/* Todos retornam um nó da árvore (<node>) */
/* Agrupamento apenas para economia de linhas */
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

/* Declaração dos Tipos Não-Terminais (Regras da Gramática) */
%type <node> programa lista_comandos comando declaracao atribuicao expressao termo fator

/* Precedência de Operadores (Para evitar ambiguidade) */
%left SOMADO_COM SUBTRAIDO_POR
%left MULTIPLICADO_POR DIVIDIDO_POR

%%
/* --- REGRAS GRAMATICAIS --- */

/* Regra Inicial */
programa: 
    lista_comandos {
        /* Cria o nó raiz 'program' e anexa a lista de comandos nele */
        Node* raiz = criar_no("program", NULL);
        adicionar_filho(raiz, $1);
        
        /* IMPRIME A ÁRVORE FINAL */
        imprimir_arvore(raiz, 0); 
    }
;

lista_comandos:
    comando lista_comandos {
        /* Encadeia os comandos numa lista */
        $1->proximo = $2;
        $$ = $1;
    }
    | comando {
        $$ = $1;
    }
;

/* Regras */
comando:
    declaracao { $$ = $1; }
    | atribuicao { $$ = $1; }
    /* ... if, while, function ... */
;

declaracao:
    MATRICULA_ADIADA ID SEMI {
        /* Exemplo: MATRICULA_ADIADA x; */
        Node* decl = criar_no("declaration", NULL);
        adicionar_filho(decl, criar_no("type", "MATRICULA_ADIADA"));
        adicionar_filho(decl, $2);
        $$ = decl;
    }
;

atribuicao:
    ID EH expressao SEMI {
        /* Exemplo: x EH 10; */
        Node* attrib = criar_no("attribution", NULL);
        adicionar_filho(attrib, $1);
        adicionar_filho(attrib, $3);
        $$ = attrib;
    }
;

expressao:
    expressao SOMADO_COM termo {
        Node* op = criar_no("op", "+");
        adicionar_filho(op, $1);
        adicionar_filho(op, $3);
        $$ = op;
    }
    | termo { $$ = $1; }
;

termo:
    termo MULTIPLICADO_POR fator {
        Node* op = criar_no("op", "*");
        adicionar_filho(op, $1);
        adicionar_filho(op, $3);
        $$ = op;
    }
    | termo DIVIDIDO_POR fator {
        Node* op = criar_no("op", "/");
        adicionar_filho(op, $1);
        adicionar_filho(op, $3);
        $$ = op;
    }
    | fator { $$ = $1; }
;

fator:
    INT { $$ = $1; }
    | REAL { $$ = $1; }
    | ID { $$ = $1; }
    | LPAREN expressao RPAREN { 
        /* Regra para ( 10 + 5 ) */
        $$ = $2; 
    }
;

%%
/* --- CÓDIGO C --- */

Node* criar_no(char* tipo, char* valor) {
    Node* n = (Node*)malloc(sizeof(Node));
    n->tipo = strdup(tipo);
    if (valor) n->valor = strdup(valor);
    else n->valor = NULL;
    n->num_filhos = 0;
    n->proximo = NULL;
    for(int i=0; i<4; i++) n->filhos[i] = NULL;
    return n;
}

void adicionar_filho(Node* pai, Node* filho) {
    if (pai->num_filhos < 4) {
        pai->filhos[pai->num_filhos++] = filho;
    }
}

void imprimir_arvore(Node* raiz, int nivel) {
    if (raiz == NULL) return;

    // 1. Imprime a indentação
    for (int i = 0; i < nivel; i++) printf("  ");

    // 2. Imprime o nó
    if (raiz->valor) {
        // Se tem valor, mostra APENAS o valor (ex: "INT", "X", "5", "<")
        printf("%s\n", raiz->valor); 
    } else {
        // Se não tem valor (ex: "program", "statement"), imprime o tipo
        printf("%s\n", raiz->tipo);
    }

    // 3. Imprime os filhos recursivamente
    for (int i = 0; i < raiz->num_filhos; i++) {
        imprimir_arvore(raiz->filhos[i], nivel + 1);
    }

    // 4. Imprime o próximo comando (mesmo nível)
    if (raiz->proximo) {
        imprimir_arvore(raiz->proximo, nivel);
    }
}

void yyerror(const char *s) {
    fprintf(stderr, "Erro Sintatico: %s\n", s);
}

int main() {
    yyparse();
    return 0;
}