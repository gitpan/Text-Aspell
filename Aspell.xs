#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* $Id: Aspell.xs,v 1.4 2002/08/27 06:22:51 moseley Exp $ */

#include <aspell.h>

#define MAX_ERRSTR_LEN 1000

typedef struct {
    AspellCanHaveError  *ret;
    AspellSpeller       *speller;
    AspellConfig        *config;
    char                lastError[MAX_ERRSTR_LEN+1];
    int                 errnum;
} Aspell_object;

// Available options -- from section 4.2 of Aspell 0.50.1

char *Option_List[] = {
    // Dictionary Options
    "master",           // (string) base name of the dictionary to use. If this option is specifed than Aspell with either use this dictionary or die.
    "dict-dir",         // (dir) location of the main word list
    "lang",             // (string) language to use
    "size",             // (string) the preferred size of the word list
    "jargon",           // (string) an extra information to distinguish two different words lists that have the same lang and size.
    "word-list-path",   // (list) search path for word list information files
    "module-search-order", // (list) list of available modules, modules that come first on this list have a higher priority. Currently there is only one speller module.
    "personal",         // (file) personal word list file name
    "repl",             // (file) replacements list file name
    "extra-dicts",      // (list) extra dictionaries to use.
    // strip-accents

    // Checker Options
    "ignore",           // (integer) ignore words <= n chars
    "ignore-case",      // (boolean) ignore case when checking words
    "ignore-accents",   // (boolean) ignore accents when checking words
    "ignore-repl",      // (boolean) ignore commands to store replacement pairs
    "save-repl",        // (boolean) save the replacement word list on save allkeyboard (file) the base name of the keyboard definition file to use
    "sug-mode",         // (mode) suggestion mode = ultra | fast | normal | bad-spellers

    // Filters
    "filter",           // (list) add or removes a filter
    "mode",             // (string) sets the filter mode. Mode is one if none, url, email, sgml, or tex. (The short cut options '-e' may be used for email, '-H' for Html/Sgml, or '-t' for Tex)
    "encoding",         // (string) The encoding the input text is in. Valid values are ``utf-8'', ``iso8859-*'', ``koi8-r'', ``viscii'', ``cp1252'', ``machine unsigned 16'', ``machine unsigned 32''. However, the aspell utility will currently only function correctly with 8-bit encodings. I hope to provide utf-8 support in the future. The two ``machine unsigned'' encodings are entended to be used by other programs using the Aspell librarary and it is unlikly the Aspell utility will ever support these encodings.
    "email-quote",      // (list) email quote characters
    "email-margin",     // (integer) num chars that can appear before the quote char
    "sgml-check",       // (list) sgml attributes to always check.
    "sgml-extension",   // (list) sgml file extensions.
    "tex-command",      // (list) TEX commands
    "tex-check-comments", // (boolean) check TEX comments    

    // Run-together Word Options
    "run-together",     // (boolean) consider run-together words legal
    "run-together-limit", // (integer) maximum numbers that can be strung together
    "run-together-min", // (integer) minimal length of interior words

    // Misc Options
    "conf",             // (file) main configuration file
    "conf-dir",         // (dir) location of main configuration file
    "data-dir",         // (dir) location of language data files
    "local-data-dir",   // (dir) alternative location of language data files. This directory is searched before data-dir. It defaults to the same directory the actual main word list is in (which is not necessarily dict-dir).
    "home-dir",         // (dir) location for personal files
    "per-conf",         // (file) personal configuration file
    "prefix",           // (dir) prefix directory
    "set-prefix",       // (boolean) set the prefix based on executable location (only works on Win32 and when compiled with --enable-win32-relocatable)

    // Aspell Utility Options
    // backup
    // time
    "reverse",          // (boolean) reverse the order of the suggestions list.
    "keymapping",       // (string) the keymapping to use. Either aspell for the default mapping or ispell to use the same mapping that the ispell utility uses.    

    0          
};

int _create_speller(Aspell_object *self)
{
    AspellCanHaveError *ret;

    ret = new_aspell_speller(self->config);
    delete_aspell_config(self->config);
    self->config = NULL;

    if ( (self->errnum = aspell_error_number(ret) ) )
    {
        strncpy(self->lastError, (char*) aspell_error_message(ret), MAX_ERRSTR_LEN);
        return 0;
    }

    self->speller = to_aspell_speller(ret);
    self->config  = aspell_speller_config(self->speller);
    return 1;
}        




MODULE = Text::Aspell        PACKAGE = Text::Aspell


# Make sure that we have at least xsubpp version 1.922.
REQUIRE: 1.922

Aspell_object *
new(CLASS)
    char *CLASS
    CODE:
        RETVAL = (Aspell_object*)safemalloc( sizeof( Aspell_object ) );
        if( RETVAL == NULL ){
            warn("unable to malloc Aspell_object");
            XSRETURN_UNDEF;
        }
        memset( RETVAL, 0, sizeof( Aspell_object ) );

        // create the configuration
        RETVAL->config = new_aspell_config();

        // Set initial default
        // aspell_config_replace(RETVAL->config, "language-tag", "en");  // default language is 'EN'
    
    OUTPUT:
        RETVAL


void
DESTROY(self)
    Aspell_object *self
    CODE:
        if ( self->speller )
            delete_aspell_speller(self->speller); 

        safefree( (char*)self );


int
create_speller(self)
    Aspell_object *self
    CODE:
        if ( !_create_speller(self) )
            XSRETURN_UNDEF;

        RETVAL = 1;            

    OUTPUT:
        RETVAL

int
print_config(self)
    Aspell_object *self
    PREINIT:
        char ** opt;
    CODE:
        self->lastError[0] = '\0';

        /*
        if (!self->speller)
        {
            strcpy(self->lastError, "Can't list config, no speller available");
            XSRETURN_UNDEF;
        }
        */

        for (opt=Option_List; *opt; opt++) 
            PerlIO_printf(PerlIO_stdout(),"%20s:  %s\n", *opt, aspell_config_retrieve(self->config, *opt) );

        RETVAL = 1;

    OUTPUT:
        RETVAL


int
set_option(self, tag, val )
    Aspell_object *self
    char *tag
    char *val
    CODE:
        self->lastError[0] = '\0';

        aspell_config_replace(self->config, tag, val );

        if ( (self->errnum = aspell_config_error_number( (const AspellConfig *)self->config) ) )
        {
            strcpy(self->lastError, aspell_config_error_message( (const AspellConfig *)self->config ) );
            XSRETURN_UNDEF;
        }

        RETVAL = 1;
    OUTPUT:
        RETVAL
    


int
remove_option(self, tag )
    Aspell_object *self
    char *tag
    CODE:
        self->lastError[0] = '\0';

        aspell_config_remove(self->config, tag );
        
        if ( (self->errnum = aspell_config_error_number( (const AspellConfig *)self->config) ) )
        {
            strcpy(self->lastError, aspell_config_error_message( (const AspellConfig *)self->config ) );
            XSRETURN_UNDEF;
        }

        RETVAL = 1;
    OUTPUT:
        RETVAL

char *
get_option(self, val)
    Aspell_object *self
    char *val
    CODE:
        self->lastError[0] = '\0';

        RETVAL = (char *)aspell_config_retrieve(self->config, val);

        if ( (self->errnum = aspell_config_error_number( (const AspellConfig *)self->config) ) )
        {
            strcpy(self->lastError, aspell_config_error_message( (const AspellConfig *)self->config ) );
            XSRETURN_UNDEF;
        }

    OUTPUT:
        RETVAL


char *
errstr(self)
    Aspell_object *self
    CODE:
        RETVAL = (char*) self->lastError;
    OUTPUT:
        RETVAL

int
errnum(self)
    Aspell_object *self
    CODE:
        RETVAL = self->errnum;
    OUTPUT:
        RETVAL


int
check(self,word)
    Aspell_object *self
    char * word
    CODE:
        self->lastError[0] = '\0';
        self->errnum = 0;
        
        if (!self->speller && !_create_speller(self) )
            XSRETURN_UNDEF;

        RETVAL = aspell_speller_check(self->speller, word, -1);
        if (RETVAL != 1 && RETVAL != 0)
        {
            self->errnum = aspell_speller_error_number( (const AspellSpeller *)self->speller );
            strncpy(self->lastError, (char*) aspell_speller_error_message(self->speller), MAX_ERRSTR_LEN);
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL
        
int
suggest(self, word)
    Aspell_object *self
    char * word
    PREINIT:
        const AspellWordList *wl;
        AspellStringEnumeration *els;
        const char *suggestion;
    PPCODE:
        self->lastError[0] = '\0';
        self->errnum = 0;
        
        if (!self->speller && !_create_speller(self) )
            XSRETURN_UNDEF;

        wl = aspell_speller_suggest(self->speller, word, -1);
        if (!wl)
        {
            self->errnum = aspell_speller_error_number( (const AspellSpeller *)self->speller );
            strncpy(self->lastError, (char*) aspell_speller_error_message(self->speller), MAX_ERRSTR_LEN);
            XSRETURN_UNDEF;
        }
  
        els = aspell_word_list_elements(wl);

        while ( (suggestion = aspell_string_enumeration_next(els)) )
            PUSHs(sv_2mortal(newSVpv( (char *)suggestion ,0 )));

        delete_aspell_string_enumeration(els);


int
add_to_personal(self,word)
    Aspell_object *self
    char * word
    CODE:
        self->lastError[0] = '\0';
        self->errnum = 0;
        
        if (!self->speller && !_create_speller(self) )
            XSRETURN_UNDEF;


        RETVAL = aspell_speller_add_to_personal(self->speller, word, -1);
        if ( !RETVAL )
        {
            self->errnum = aspell_speller_error_number( (const AspellSpeller *)self->speller );
            strncpy(self->lastError, (char*) aspell_speller_error_message(self->speller), MAX_ERRSTR_LEN);
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL

int
add_to_session(self,word)
    Aspell_object *self
    char * word
    CODE:
        self->lastError[0] = '\0';
        self->errnum = 0;
        
        if (!self->speller && !_create_speller(self) )
            XSRETURN_UNDEF;


        RETVAL = aspell_speller_add_to_session(self->speller, word, -1);
        if ( !RETVAL )
        {
            self->errnum = aspell_speller_error_number( (const AspellSpeller *)self->speller );
            strncpy(self->lastError, (char*) aspell_speller_error_message(self->speller), MAX_ERRSTR_LEN);
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL



int
store_replacement(self,word,replacement)
    Aspell_object *self
    char * word
    char * replacement
    CODE:
        self->lastError[0] = '\0';
        self->errnum = 0;
        
        if (!self->speller && !_create_speller(self) )
            XSRETURN_UNDEF;


        RETVAL = aspell_speller_store_replacement(self->speller, word, -1, replacement, -1);
        if ( !RETVAL )
        {
            self->errnum = aspell_speller_error_number( (const AspellSpeller *)self->speller );
            strncpy(self->lastError, (char*) aspell_speller_error_message(self->speller), MAX_ERRSTR_LEN);
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL

int
save_all_word_lists(self)
    Aspell_object *self
    CODE:
        self->lastError[0] = '\0';
        self->errnum = 0;
        
        if (!self->speller && !_create_speller(self) )
            XSRETURN_UNDEF;


        RETVAL = aspell_speller_save_all_word_lists(self->speller);
        if ( !RETVAL )
        {
            self->errnum = aspell_speller_error_number( (const AspellSpeller *)self->speller );
            strncpy(self->lastError, (char*) aspell_speller_error_message(self->speller), MAX_ERRSTR_LEN);
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL
        
int
clear_session(self)
    Aspell_object *self
    CODE:
        self->lastError[0] = '\0';
        self->errnum = 0;
        
        if (!self->speller && !_create_speller(self) )
            XSRETURN_UNDEF;


        RETVAL = aspell_speller_clear_session(self->speller);
        if ( !RETVAL )
        {
            self->errnum = aspell_speller_error_number( (const AspellSpeller *)self->speller );
            strncpy(self->lastError, (char*) aspell_speller_error_message(self->speller), MAX_ERRSTR_LEN);
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL


int
list_dictionaries(self)
    Aspell_object *self
    PREINIT:
        AspellDictInfoList * dlist;
        AspellDictInfoEnumeration * dels;
        const AspellDictInfo * entry;
    PPCODE:
        if (!self->config )
            XSRETURN_UNDEF;


        dlist = get_aspell_dict_info_list(self->config);
        dels = aspell_dict_info_list_elements(dlist);

        while ( (entry = aspell_dict_info_enumeration_next(dels)) != 0)
        {
            int  len;
            char *dictname;

            len = strlen( entry->name ) +
                  strlen( entry->jargon ) +
                  strlen( entry->code ) +
                  strlen( entry->size_str ) +
                  strlen( entry->module->name ) + 4;


            dictname = (char *)safemalloc( len + 1 );
            sprintf( dictname, "%s:%s:%s:%s:%s", entry->name, entry->code, entry->jargon, entry->size_str, entry->module->name );

            PUSHs(sv_2mortal(newSVpv( dictname ,0 )));
            safefree( dictname );
        }

        delete_aspell_dict_info_enumeration(dels);

