# **Relatório – SIGAALang: Analisador Léxico e Sintático (Flex + Bison)**

**Disciplina:** MATA61 - Compiladores  
**Professor:** Adriano Maia  
**Equipe:** Beatriz Cerqueira Brandão de Jesus, Priscila Conceição Araújo, Roberio Gomes de Oliveira, Vinicius Coutinho  
**Semestre:** 2025.2

## **1. Introdução**

Este trabalho apresenta a implementação do analisador léxico e sintático da linguagem **SIGAALang**, desenvolvida especificamente para este projeto. A linguagem é imperativa e incorpora elementos sintáticos inspirados no contexto acadêmico fictício do SIGAA, mas com operadores, palavras-chave e estruturas deliberadamente incomuns, o que reforça o exercício de projetar, formalizar e implementar uma gramática não trivial.

A construção do analisador utiliza **Flex** para a fase de análise léxica e **Bison** para a análise sintática, seguindo os requisitos estabelecidos no enunciado do Trabalho 2 .  

Como resultado, o programa final reconhece códigos escritos na linguagem **SIGAALang** e produz a árvore sintática completa, contendo nós para comandos, expressões, funções, vetores e operadores aritméticos.

Este relatório descreve as escolhas feitas na definição da gramática, a função de cada componente e como o conjunto Flex+Bison foi integrado.

## **2. Analisador Léxico (`lexer.l`)**

O analisador léxico tem o papel de identificar os tokens da linguagem e produzir valores (via `yylval`) que serão usados pelo Bison para compor a árvore sintática.

### **2.1 Estrutura e rastreamento de posição**

O arquivo inicia com:

* inclusão de `parser.tab.h`,
* definição de uma função `atualiza_pos()` que atualiza linha e coluna,
* armazenamento de valores léxicos através de `criar_no("num", yytext)` e `criar_no("id", yytext)`.

Esse design já prepara, no estágio léxico, os nós que representarão números e identificadores na árvore sintática.

### **2.2 Palavras-chave**

Um aspecto distintivo da **SIGAALang** é a escolha de palavras-chave longas, expressivas e incomuns, como:

* `MATRICULA_ADIADA`,
* `TRANCAMENTO_ADIADO`,
* `TEMPORARIAMENTE_INDISPONIVEL`,
* `TENTE_NOVAMENTE_MAIS_TARDE`,
* `CAOS_GENERALIZADO`,
* `INCONSISTENCIA_DE_DADOS`, etc.

Essas palavras-chave representam tipos, comandos de controle, declarações de função e operadores lógicos/situacionais.

### **2.3 Literais**

**SIGAALang** aceita:

* **inteiros** `(INT: [0-9]+)`,
* **reais com notação opcional científica** `(REAL: [0-9]+\.[0-9]+([eE][+-]?[0-9]+)?)`.

Ambos são transformados imediatamente em nós da árvore, carregados em `yylval.node`.

### **2.4 Identificadores**

A regra:

```
ID [A-Za-z][A-Za-z0-9]*
```

permite nomes iniciando por letra e seguidos de letras ou dígitos.

### **2.5 Símbolos**

O lexer reconhece:

```
( ) [ ] { } ; ,
```

que serão usados na gramática para vetores, blocos, chamadas de função e organização de expressões.

### **2.6 Comentários e espaços em branco**

* espaços, tabs e quebras de linha são ignorados,
* um padrão de comentário abreviado (`COMM`) é aceito e descartado.

### **2.7 Tratamento de erro**

Qualquer caractere não reconhecido dispara:

```
Erro Léxico: <caractere>
```

Essa abordagem é suficiente para o nível do trabalho, permitindo identificar rapidamente caracteres inválidos.

## **3. Analisador Sintático (`parser.y`)**

O parser da **SIGAALang** foi construído com foco em clareza estrutural e produção explícita da árvore sintática.  

Cada regra do Bison constrói um nó da árvore através da função `criar_no()` e associa seus filhos com `adicionar_filho()`.

A árvore é impressa ao final do programa, respeitando a hierarquia definida pela gramática.

## **4. Estrutura da Árvore e Representação Interna**

O nó é definido como:

```
typedef struct Node {
    char *tipo;
    char *valor;
    Node *filhos[8];
    int num_filhos;
    Node *proximo;
} Node;
```

Essa estrutura permite:

* representação de listas encadeadas (`proximo`),
* nós heterogêneos com tipos variados,
* até 8 filhos diretos por nó, suficiente para as construções da linguagem.

## **5. Gramática da SIGAALang: Decisões e Justificativas**

A seguir, descrevemos cada parte da gramática, justificando as escolhas sintáticas.

### **5.1 Programa e lista de comandos**

```
programa → lista_comandos
```

A raiz da árvore sempre contém um único nó *program*, permitindo que diferentes comandos sejam processados de modo uniforme.  

A lista de comandos é ligada através do campo *proximo*, funcionando como uma lista encadeada.

### **5.2 Comandos**

**SIGAALang** possui:

* declarações (`MATRICULA_ADIADA x;`)
* atribuições (`x EH 5;`)
* acesso e atribuição a vetores
* condicionais com palavras-chave cômicas (`TEMPORARIAMENTE_INDISPONIVEL (...)`)
* `if`/`else` através da combinação com `TENTE_NOVAMENTE_MAIS_TARDE`
* laços do tipo while representados por `CAOS_GENERALIZADO`
* definição de funções (`INCONSISTENCIA_DE_DADOS tipo nome (...) { ... }`)
* retorno de funções (`DESESPERO_ESTUDANTIL expr;`)

A escolha de nomes está diretamente relacionada ao tema humorístico da linguagem, mas a estrutura sintática se mantém convencional internamente.

### **5.3 Declarações**

Há dois tipos centrais:

#### **5.3.1 Declaração de variável simples**

```
MATRICULA_ADIADA ID ;
```

Gera um nó:

```
declaration  
 ├─ type ("MATRICULA_ADIADA")  
 └─ id
```

#### **5.3.2 Declaração de vetor**

```
VETOR MATRICULA_ADIADA nome EH [ lista_valores ]
```

A árvore segue:

```
vector_decl  
 ├─ type ("VETOR MATRICULA_ADIADA")  
 ├─ id  
 └─ list (valores iniciais)
```

A regra suporta listas heterogêneas de expressões, permitindo vetores inicializados de forma explícita.

### **5.4 Atribuições**

Há duas formas:

#### **5.4.1 Atribuição simples**

```
x EH expressao ;
```

Nó:

```
attribution  
 ├─ id  
 └─ expressao
```

#### **5.4.2 Atribuição em vetor**

```
x NA_POSICAO expr EH expr ;
```

Esse design combina acesso à posição com atribuição, seguindo estilo natural da linguagem.

### **5.5 Expressões Aritméticas**

**SIGAALang** usa operadores verbosos:

* `soma → SOMADO_COM`
* `subtração → SUBTRAIDO_POR`
* `multiplicação → MULTIPLICADO_POR`
* `divisão → DIVIDIDO_POR`

O parser cria explicitamente nós de operação:

```
op "+"  
 ├─ expr  
 └─ termo
```

A precedência é definida corretamente via:

```
%left SOMADO_COM SUBTRAIDO_POR
%left MULTIPLICADO_POR DIVIDIDO_POR
```

que mantém a hierarquia adequada dentro das expressões.

### 

### **5.6 Fatores**

Fatores incluem:

* literais (`INT`, `REAL`),
* identificadores,
* acesso a vetor,
* chamadas de função,
* expressões entre parênteses.

Uma regra importante:

```
ID NA_POSICAO expressao  
→ vector_access
```

Outra:

```
ID ( lista_argumentos )  
→ call
```

Essas escolhas mantêm o aspecto imperativo da linguagem, permitindo composição de expressões complexas.

### **5.7 Funções**

A definição de funções é particularmente expressiva:

```
INCONSISTENCIA_DE_DADOS tipo_retorno nome ( parametros ) { comandos }
```

Cada função gera árvore:

```
function_def  
 ├─ return_type  
 ├─ id  
 ├─ params  
 └─ commands
```

As palavras-chave de retorno incluem:

* `MATRICULA_ADIADA`,
* `TRANCAMENTO_ADIADO`,
* `ERRO_NA_ALOCACAO`.

### **5.8 Retorno de função**

```
DESESPERO_ESTUDANTIL expr ;
```

Gera:

```
return  
 └─ expr
```

### **5.9 Estruturas de controle**

#### **5.9.1 If**

```
TEMPORARIAMENTE_INDISPONIVEL (expr) { comandos }
```

#### **5.9.2 If/Else**

```
... TENTE_NOVAMENTE_MAIS_TARDE { comandos }
```

#### **5.9.3 While**

```
CAOS_GENERALIZADO (expr) { comandos }
```

Todos produzem árvores claras e diretas (`if`, `if_else`, `while`).

## **6. Lista de Argumentos e Parâmetros**

A gramática suporta:

* lista vazia,
* lista encadeada,
* parâmetros tipados (`MATRICULA_ADIADA x`).

Essa modularidade permite expandir facilmente a linguagem para incluir parâmetros variados.

## **7. Impressão da Árvore**

A função `imprimir_arvore()`:

* exibe cada nó com indentação proporcional ao nível,
* imprime valor quando presente (para números e identificadores),
* percorre listas encadeadas (`proximo`).

O resultado é uma árvore legível e informativa, similar ao exemplo exigido no trabalho.

## **8. Conclusão**

A linguagem **SIGAALang**, utilizando-se do humor nos nomes das palavras-chave, foi projetada com seriedade em termos de:

* coerência sintática,
* modularidade das regras,
* distinção clara entre declaração, comando, expressão e fator,
* suporte natural a vetores, funções, retorno, acesso indexado, operações aritméticas e controle de fluxo.

O uso combinado de Flex e Bison permitiu construir um analisador sintático capaz de receber a entrada, verificar sua conformidade com a linguagem e gerar uma árvore sintática detalhada que representa adequadamente a estrutura do programa.
