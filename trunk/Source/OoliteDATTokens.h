#ifndef INCLUDED_OOLITEDATTOKENS_h
#define INCLUDED_OOLITEDATTOKENS_h

enum
{
	KOoliteDatToken_EOF,
	KOoliteDatToken_EOL,
	KOoliteDatToken_VERTEX_SECTION,
	KOoliteDatToken_FACES_SECTION,
	KOoliteDatToken_TEXTURES_SECTION,
	KOoliteDatToken_END_SECTION,
	KOoliteDatToken_NVERTS,
	KOoliteDatToken_NFACES,
	KOoliteDatToken_INTEGER,
	KOoliteDatToken_REAL,
	KOoliteDatToken_STRING
};


#ifdef __cplusplus
extern "C" {
#endif

extern int OoliteDAT_yylex(void);
extern void OoliteDAT_SetInputFile(FILE *inFile);
extern int OoliteDAT_LineNumber(void);
extern char *OoliteDAT_yytext;

#ifdef __cplusplus
}
#endif

#endif	/* INCLUDED_OOLITEDATTOKENS_h */
