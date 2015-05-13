#import "DocPreview2.h"

@implementation NSAttributedString(HTMLConversionUtils)

-(NSData *)HTMLData
{
    NSError *conversionErr;
    NSDictionary *conversionAttrs;
    NSData* htmlData;
    
    conversionAttrs = [NSDictionary dictionaryWithObject:NSHTMLTextDocumentType forKey:NSDocumentTypeDocumentAttribute];
    
    htmlData = [self dataFromRange:NSMakeRange(0, [self length]) documentAttributes:conversionAttrs error:&conversionErr];
    return htmlData;
}

-(NSString *)HTMLString
{
    NSString *htmlString = [[NSString alloc] initWithData:[self HTMLData] encoding:NSUTF8StringEncoding];
    return [htmlString autorelease];
}

@end

//fixes a bug in STRINGN_TO_NPVARIANT that prevents compilation on gcc4 -yliu
#undef STRINGN_TO_NPVARIANT
#define STRINGN_TO_NPVARIANT(_val, _len, _v)                                  \
NP_BEGIN_MACRO                                                                \
(_v).type = NPVariantType_String;                                         \
NPString str = { _val, (uint32_t)(_len) };                                \
(_v).value.stringValue = str;                                             \
NP_END_MACRO

// structure containing pointers to functions implemented by the browser
static NPNetscapeFuncs* browser;

// data for each instance of this plugin
typedef struct PluginInstance {
    NPP npp;
    NPWindow window;
} PluginInstance;

static FILE *s_log;

static void logmsg(const char *format, ...) {
    va_list args;
    
    if (s_log == NULL) {
        s_log = fopen("/tmp/docpreview_debug.log", "a");
        if (s_log == NULL) {
            s_log = stderr;
        }
    }
    va_start(args, format);
    vfprintf(s_log, format, args);
    fputc('\n', s_log);
    fflush(s_log);
    va_end(args);
    
}


//void drawPlugin(NPP instance, NPCocoaEvent* event);

// Symbol called once by the browser to initialize the plugin
NPError NP_Initialize(NPNetscapeFuncs* browserFuncs)
{
    // save away browser functions
    browser = browserFuncs;
    
    return NPERR_NO_ERROR;
}

// Symbol called by the browser to get the plugin's function list
NPError NP_GetEntryPoints(NPPluginFuncs* pluginFuncs)
{
    // Check the size of the provided structure based on the offset of the
    // last member we need.
    if (pluginFuncs->size < (offsetof(NPPluginFuncs, setvalue) + sizeof(void*)))
        return NPERR_INVALID_FUNCTABLE_ERROR;
    
    /* the minimum set of functions that must be provided */
    pluginFuncs->newp = NPP_New;
    pluginFuncs->destroy = NPP_Destroy;
    pluginFuncs->setwindow = NPP_SetWindow;
    pluginFuncs->newstream = NPP_NewStream;
    pluginFuncs->destroystream = NPP_DestroyStream;
    pluginFuncs->asfile = NPP_StreamAsFile;
    pluginFuncs->writeready = NPP_WriteReady;
    pluginFuncs->write = (NPP_WriteProcPtr)NPP_Write;
    pluginFuncs->print = NPP_Print;
    pluginFuncs->event = NPP_HandleEvent;
    pluginFuncs->urlnotify = NPP_URLNotify;
    pluginFuncs->getvalue = NPP_GetValue;
    pluginFuncs->setvalue = NPP_SetValue;
    
    return NPERR_NO_ERROR;
}

// Symbol called once by the browser to shut down the plugin
void NP_Shutdown(void)
{

}

// Called to create a new instance of the plugin
NPError NPP_New(NPMIMEType pluginType, NPP instance, uint16_t mode, int16_t argc, char* argn[], char* argv[], NPSavedData* saved)
{
    PluginInstance *newInstance = (PluginInstance*)malloc(sizeof(PluginInstance));
    bzero(newInstance, sizeof(PluginInstance));
    
    newInstance->npp = instance;
    instance->pdata = newInstance;
    
    return NPERR_NO_ERROR;
}

// Called to destroy an instance of the plugin
NPError NPP_Destroy(NPP instance, NPSavedData** save)
{
    free(instance->pdata);
    
    return NPERR_NO_ERROR;
}

// Called to update a plugin instances's NPWindow
NPError NPP_SetWindow(NPP instance, NPWindow* window)
{
    PluginInstance* currentInstance = (PluginInstance*)(instance->pdata);
    
    currentInstance->window = *window;
    
    return NPERR_NO_ERROR;
}


NPError NPP_NewStream(NPP instance, NPMIMEType type, NPStream* stream, NPBool seekable, uint16_t* stype)
{
    *stype = NP_ASFILEONLY;
    return NPERR_NO_ERROR;
}

NPError NPP_DestroyStream(NPP instance, NPStream* stream, NPReason reason)
{
    return NPERR_NO_ERROR;
}

int32_t NPP_WriteReady(NPP instance, NPStream* stream)
{
    return 0;
}

int32_t NPP_Write(NPP instance, NPStream* stream, int32_t offset, int32_t len, void* buffer)
{
    return 0;
}

void NPP_StreamAsFile(NPP instance, NPStream* stream, const char* fname)
{
}

void NPP_Print(NPP instance, NPPrint* platformPrint)
{
    
}

int16_t NPP_HandleEvent(NPP instance, void* event)
{
    NPCocoaEvent* cocoaEvent = (NPCocoaEvent*)event;
    if (cocoaEvent && (cocoaEvent->type == NPCocoaEventDrawRect)) {
        //drawPlugin(instance, (NPCocoaEvent*)event);
        return 1;
    }
    
    return 0;
}

void NPP_URLNotify(NPP instance, const char* url, NPReason reason, void* notifyData)
{
    
}

typedef struct ExtendedNPObject {
    // bit of a hack to "inherit" from a struct. you should still be able to downcast it and call an NPObject member
    NPObject obj; // NOTE: NPObject must always be first in the extended struct
    NPP npp;
} ExtendedNPObject;

static NPObject* object_with_instance_allocate(NPP npp, NPClass *aClass)
{
    ExtendedNPObject *e_obj = (ExtendedNPObject*)malloc(sizeof(ExtendedNPObject));
    return (NPObject*)e_obj;
}

static void object_with_instance_deallocate(NPObject *e_obj)
{
    free(e_obj);
}

static bool
hasMethod(NPObject* obj, NPIdentifier methodName) {
    return true;
}

static bool
invokeDefault(NPObject *obj, const NPVariant *args, uint32_t argCount, NPVariant *result) {
    result->type = NPVariantType_Int32;
    result->value.intValue = 42;
    return true;
}

static NPUTF8* createCStringFromNPVariant(const NPVariant* variant)
{
    /* the output of this function needs to be freed by the caller */
    size_t length = NPVARIANT_TO_STRING(*variant).UTF8Length;
    NPUTF8* result = (NPUTF8*)malloc(length + 1);
    memcpy(result, NPVARIANT_TO_STRING(*variant).UTF8Characters, length);
    result[length] = '\0';
    return result;
}



static bool
invoke(NPObject* obj, NPIdentifier methodName, const NPVariant *args, uint32_t argCount, NPVariant *result) {
    char *name = browser->utf8fromidentifier(methodName);
    if(name) {
        if(!strcmp(name, "version")) {
            result->type = NPVariantType_Int32;
            result->value.intValue = BUILD_VERSION;
            return true;
            //return invokeDefault(obj, args, argCount, result);
        }
        else if (!strcmp(name, "doc2html"))
        {
            if(argCount == 1 && args[0].type == NPVariantType_String)
            {
                NSDictionary* attrs = NULL;
                NSError *err = NULL;
                NPUTF8* b64_c_string = createCStringFromNPVariant(&args[0]);
                // first we decode the base64 string representation of the (possibly) binary arrayBuffer sent to the plugin
                NSString* b64_string = [[NSString alloc] initWithUTF8String:b64_c_string];
                NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:b64_string options:0];
                //NSAttributedString *attr_s = [[NSAttributedString alloc] initWithDocFormat:decodedData documentAttributes:0];
                
                // here is where the magic conversion happens
                NSAttributedString* attr_s = [[NSAttributedString alloc] initWithData:decodedData options:nil documentAttributes:&attrs error:&err];
                // create the HTML representation
                NSString* html = [[attr_s HTMLString] retain];
                const char* html_c_string = [html UTF8String];
                unsigned long n = strlen(html_c_string);
                char *html_output = (char *)browser->memalloc(n+1); //browser should be responsible for freeing this
                memcpy(html_output, html_c_string, n);
                html_output[n]='\0';
                
                // convert back to NPVariant for browser use and copy it to the result structure for return
                STRINGN_TO_NPVARIANT(html_output, n, *result);
                /*result->type = NPVariantType_String;
                result->value.stringValue.UTF8Characters = html_output;
                result->value.stringValue.UTF8Length = n;*/
                [html release];
                [attr_s release];
                [decodedData release];
                [b64_string release];
                free(b64_c_string);
                return true;
            }
            browser->setexception(obj, "not a string passed into doc2html");
            return false;
        }
        /*else if(!strcmp(name, "callback")) {
            if(argCount == 1 && args[0].type == NPVariantType_Object) {
                //static NPVariant v, r;
                NSString *test = @"Hello world from Objective-C type!";
                const char *kHello = [test UTF8String];
                char *txt = (char *)browser->memalloc([test length]);
                
                memcpy(txt, kHello, [test length]);
                STRINGN_TO_NPVARIANT(txt, [test length], v);
                if(browser->invokeDefault(((ExtendedNPObject*)obj)->npp, NPVARIANT_TO_OBJECT(args[0]), &v, 1, &r))
                    return invokeDefault(obj, args, argCount, result);
            }
        }*/
    }
    /* aim exception handling */
    browser->setexception(obj, "exception during invocation");
    return false;
}

static bool
hasProperty(NPObject *obj, NPIdentifier propertyName) {
    return false;
}

static bool
getProperty(NPObject *obj, NPIdentifier propertyName, NPVariant *result) {
    return false;
}


static NPClass npcRefObject = {
    NP_CLASS_STRUCT_VERSION,
    &object_with_instance_allocate,
    &object_with_instance_deallocate,
    NULL,
    hasMethod,
    invoke,
    invokeDefault,
    hasProperty,
    getProperty,
    NULL,
    NULL,
};



NPError NPP_GetValue(NPP instance, NPPVariable variable, void *value)
{
    NPObject *so;
    switch(variable) {
        default:
            return NPERR_GENERIC_ERROR;
        case NPPVpluginNameString:
            *((char **)value) = "DocPreview2";
            break;
        case NPPVpluginDescriptionString:
            *((char **)value) = "Generates a HTML representation of Word, Rich Text, or Open Document Format documents for in-browser previewing";
            break;
        case NPPVpluginScriptableNPObject:
            so = browser->createobject(instance, &npcRefObject);
            browser->retainobject(so);
            *(NPObject **)value = so;
            break;
#if defined(XULRUNNER_SDK) || defined(NPAPI_SDK)
        case NPPVpluginNeedsXEmbed:
            *((NPBool *)value) = true;
            break;
#endif
    }
    return NPERR_NO_ERROR;
}

NPError NPP_SetValue(NPP instance, NPNVariable variable, void *value)
{
    return NPERR_GENERIC_ERROR;
}

