%{
/*
 *  File:             lexer.l
 *  Date created:     March 15, 1999 (Monday, 17:16h)
 *  Author:           Thomas Jensen
 *                    tsjensen@stud.informatik.uni-erlangen.de
 *  Version:          $Id$
 *  Language:         lex (ANSI C)
 *  Purpose:          flex lexical analyzer for boxes configuration files
 *  Remarks:          ---
 *
 *  Revision History:
 *
 *    $Log$
 *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 */

/* #define DEBUG */

#include <string.h>
#include "boxes.h"
#include "y.tab.h"

#ident "$Id$"

int yylineno = 1;

%}

%x SAMPLE1
%x SAMPLE2
%s SHAPES
%s OFFSETS
%s ELASTIC

%%

<SAMPLE1,SHAPES,OFFSETS,ELASTIC,INITIAL>[\r\t ]+ /* ignore whitespace */

<SAMPLE1,SHAPES,OFFSETS,ELASTIC,INITIAL>\n yylineno++;

#[^#].*$ {
    /* ignore comments */
    #ifdef DEBUG
        fprintf (stderr, "\nCOMMENT: %s", yytext+1);
    #endif
}

\"[^"\n]*$ {
    yyerror ("Unterminated String at %s", yytext);
    exit (EXIT_FAILURE);
}

\"[^"\n]*\" {
    int bidx = yyleng-2;                 /* backslash index */

    while (yytext[bidx] == '\\') bidx--;

    if ((yyleng-2-bidx) % 2) {
        yyless (yyleng-1);               /* give back last quote */
        yymore();                        /* append next string */
    }
    else {
        for (bidx=0; bidx<yyleng-1; ++bidx) {
            if (yytext[bidx] == '\\') {
                memmove (yytext+bidx, yytext+bidx+1, yyleng-bidx-1);
                yytext[yyleng-1] = '\0';
                --yyleng;                /* inefficient */
            }
        }

        memmove (yytext, yytext+1, yyleng-1);     /* cut quotes */
        --yyleng;
        yytext[yyleng-1] = '\0';
        --yyleng;

        #ifdef DEBUG
            fprintf (stderr, "\n STRING: \"%s\"", yytext);
        #endif
        yylval.s = (char *) strdup (yytext);
        return STRING;
    }
}

Sample {
    #ifdef DEBUG
        fprintf (stderr, "\n   WORD: %s -- STATE SAMPLE1", yytext);
    #endif
    BEGIN SAMPLE1;
    return YSAMPLE;
}

<SAMPLE1>\{ {
    #ifdef DEBUG
        fprintf (stderr, "\n SYMBOL: \'%c\' -- STATE SAMPLE2", yytext[0]);
    #endif
    BEGIN SAMPLE2;
    return yytext[0];
}

<SAMPLE1>[^{]+ {
    yyerror ("Syntax Error at %s", yytext);
    exit (EXIT_FAILURE);
}

<SAMPLE2>\n {
    ++yylineno;
    if (yyleng > 1)
        yymore();
}

<SAMPLE2>\} {
    int bidx = yyleng-2;                 /* backslash index */

    if (bidx >= 0) {
        while (bidx >= 0 && yytext[bidx] == '\\') bidx--;

        if ((yyleng-2-bidx) % 2) {       /* odd number of backslashes */
            yymore();                    /* append next string */
        }
        else {
            yyless (yyleng-1);           /* have him recognize '}' symbol */

            for (bidx=yyleng-1; yytext[bidx]=='\n'; --bidx) {
                yytext[bidx] = '\0';    /* remove trailing newlines */
                --yyleng;
            }
            for (bidx=0; bidx<yyleng-1; ++bidx) {
                if (yytext[bidx] == '\\') {
                    memmove (yytext+bidx, yytext+bidx+1, yyleng-bidx-1);
                    yytext[yyleng-1] = '\0';
                    --yyleng;                   /* inefficient */
                }
            }
            BEGIN INITIAL;
            #ifdef DEBUG
                fprintf (stderr, "\n SAMPLE: %s -- STATE INITIAL", yytext);
            #endif
            yylval.s = (char *) strdup (yytext);
            return STRING;
        }
    }
    else {
        yymore();
    }
}

<SAMPLE2>. {
    yymore();
}

Offsets {
    #ifdef DEBUG
        fprintf (stderr, "\nYOFFSET: %s -- STATE OFFSETS", yytext);
    #endif
    BEGIN OFFSETS;
    return YOFFSETS;
}

elastic {
    #ifdef DEBUG
        fprintf (stderr, "\nYELASTC: %s -- STATE ELASTIC", yytext);
    #endif
    BEGIN ELASTIC;
    return YELASTIC;
}

Shapes {
    #ifdef DEBUG
        fprintf (stderr, "\nYSHAPES: %s -- STATE SHAPES", yytext);
    #endif
    BEGIN SHAPES;
    return YSHAPES;
}

<OFFSETS>nw-nnw { yylval.offset = NW_NNW; return OFFSET; }
<OFFSETS>nnw-n  { yylval.offset = NNW_N;  return OFFSET; }
<OFFSETS>n-nne  { yylval.offset = N_NNE;  return OFFSET; }
<OFFSETS>nne-ne { yylval.offset = NNE_NE; return OFFSET; }
<OFFSETS>ne-ene { yylval.offset = NE_ENE; return OFFSET; }
<OFFSETS>ene-e  { yylval.offset = ENE_E;  return OFFSET; }
<OFFSETS>e-ese  { yylval.offset = E_ESE;  return OFFSET; }
<OFFSETS>ese-se { yylval.offset = ESE_SE; return OFFSET; }
<OFFSETS>se-sse { yylval.offset = SE_SSE; return OFFSET; }
<OFFSETS>sse-s  { yylval.offset = SSE_S;  return OFFSET; }
<OFFSETS>s-ssw  { yylval.offset = S_SSW;  return OFFSET; }
<OFFSETS>ssw-sw { yylval.offset = SSW_SW; return OFFSET; }
<OFFSETS>sw-wsw { yylval.offset = SW_WSW; return OFFSET; }
<OFFSETS>wsw-w  { yylval.offset = WSW_W;  return OFFSET; }
<OFFSETS>w-wnw  { yylval.offset = W_WNW;  return OFFSET; }
<OFFSETS>wnw-nw { yylval.offset = WNW_NW; return OFFSET; }

<SHAPES,ELASTIC>nw  { yylval.shape = NW;  return SHAPE; }
<SHAPES,ELASTIC>nnw { yylval.shape = NNW; return SHAPE; }
<SHAPES,ELASTIC>n   { yylval.shape = N;   return SHAPE; }
<SHAPES,ELASTIC>nne { yylval.shape = NNE; return SHAPE; }
<SHAPES,ELASTIC>ne  { yylval.shape = NE;  return SHAPE; }
<SHAPES,ELASTIC>ene { yylval.shape = ENE; return SHAPE; }
<SHAPES,ELASTIC>e   { yylval.shape = E;   return SHAPE; }
<SHAPES,ELASTIC>ese { yylval.shape = ESE; return SHAPE; }
<SHAPES,ELASTIC>se  { yylval.shape = SE;  return SHAPE; }
<SHAPES,ELASTIC>sse { yylval.shape = SSE; return SHAPE; }
<SHAPES,ELASTIC>s   { yylval.shape = S;   return SHAPE; }
<SHAPES,ELASTIC>ssw { yylval.shape = SSW; return SHAPE; }
<SHAPES,ELASTIC>sw  { yylval.shape = SW;  return SHAPE; }
<SHAPES,ELASTIC>wsw { yylval.shape = WSW; return SHAPE; }
<SHAPES,ELASTIC>w   { yylval.shape = W;   return SHAPE; }
<SHAPES,ELASTIC>wnw { yylval.shape = WNW; return SHAPE; }

<ELASTIC>\) {
    #ifdef DEBUG
        fprintf (stderr, "\n SYMBOL: \'%c\' -- STATE INITIAL", yytext[0]);
    #endif
    BEGIN INITIAL;
    return yytext[0];
}

<SHAPES,OFFSETS>\} {
    #ifdef DEBUG
        fprintf (stderr, "\n SYMBOL: \'%c\' -- STATE INITIAL", yytext[0]);
    #endif
    BEGIN INITIAL;
    return yytext[0];
}

BOX|revision|author|created|revdate|END {
    /*
     *  general key words followed by a string
     */
    #ifdef DEBUG
        fprintf (stderr, "\nKEYWORD: %s", yytext);
    #endif
    yylval.s = (char *) strdup (yytext);
    return KEYWORD;
}

[a-zA-Z������][a-zA-Z0-9\-_�������]*  {
    #ifdef DEBUG
        fprintf (stderr, "\n   WORD: %s", yytext);
    #endif
    yylval.s = (char *) strdup (yytext);
    return WORD;
}

[,(){}] {
    #ifdef DEBUG
        fprintf (stderr, "\n SYMBOL: \'%c\'", yytext[0]);
    #endif
    return yytext[0];
}

\-?[0-9]+ {
    #ifdef DEBUG
        fprintf (stderr, "\n NUMBER: %s", yytext);
    #endif
    yylval.num = atoi (yytext);
    return NUMBER;
}

. {
    yyerror ("Unrecognized input at %s", yytext);
    exit (EXIT_FAILURE);
}


%%


/*EOF*/                                         /* vim: set cindent sw=4: */