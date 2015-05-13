function pluginCompatibleVersion()
{
    return 1;
}

if (typeof String.prototype.endsWith !== 'function') {
    String.prototype.endsWith = function(suffix) {
        return this.indexOf(suffix, this.length - suffix.length) !== -1;
    };
}

function send_http_request(uri, headers, callback, error_callback)
{
    var request = new XMLHttpRequest();
    request.responseType = 'arraybuffer';
    request.timeout = 60000;
    request.onload = function()
    {
        if (this.status === 200) {
            callback(request, uri);
        }
        else
        {
            console.log(this.status);
            error_callback(request, uri);
        }
    };
    request.ontimeout = function () { console.warn("Connection timed out", uri); };
    request.onerror = function() {console.warn("There was a network error and this request just fired onerror.", uri);};
    request.open('GET', uri);
    // headers here
    var header_keys = Object.keys(headers);
    for (var i=0; i<header_keys.length; i++)
    {
        request.setRequestHeader(header_keys[i], headers[header_keys[i]]);
    }
    request.send();
}


function extractURI(target)
{
    
    if (target.nodeName === "A")
    {
        return target.href;
    }
    return null;
}

function notifyClient(data, msgID, msgEvent)
{
    var page = safari.application.activeBrowserWindow.activeTab.page;
    if (msgEvent && msgEvent.target && msgEvent.target.page)
        page = msgEvent.target.page;
    page.dispatchMessage(msgID, data);
}

function notifyAllClients(data, msgID)
{
    for (var i = 0; i < safari.application.browserWindows.length; i++)
    {
        var browserWindow = safari.application.browserWindows[i];
        for (var j = 0; j < browserWindow.tabs.length; j++)
        {
            var tab = browserWindow.tabs[j];
            if (tab && tab.page)
            {
                tab.page.dispatchMessage(msgID, data);
            }
        }
    }
    
}

function arrayBufferToBase64( buffer ) {
    var binary = '';
    var bytes = new Uint8Array( buffer );
    var len = bytes.byteLength;
    for (var i = 0; i < len; i++) {
        binary += String.fromCharCode( bytes[ i ] );
    }
    return window.btoa( binary );
}

function UTF8ToBase64(str) {
    return window.btoa(unescape(encodeURIComponent(str)));
}

function getPluginToolbar()
{
    if (safari.extension.bars[0])
        return safari.extension.bars[0];
}

function getDocPreviewPlugin()
{
    try {
        var toolbar = getPluginToolbar();
        var toolbarWindow = toolbar.contentWindow;
        var doc = toolbarWindow.document;
        var plugin = doc.getElementById("docpreview2");
        if (plugin && plugin.version)
            return plugin;
        else
        {
            console.error("DocPreview NPAPI plugin failed to activate");
        }
    }
    catch(e)
    {
        console.error("DocPreview NPAPI plugin failed to activate due to exception", e);
        alert("Exception");
    }
    return null;
    
}

function doc2html(doc)
{
    var b64doc = arrayBufferToBase64(doc);;
    var html = null;
    var toolbar = getPluginToolbar();
    toolbar.show();
    var docpreview = getDocPreviewPlugin();
    if (docpreview)
    {
        //console.log(b64doc);
        html = docpreview.doc2html(b64doc);
        toolbar.hide(); // flicker the toolbar on and off to solve an issue from Safari 8.0.4 where plugins in the toolbar are not loaded unless the toolbar itself is visible.
        return html;
    }
    else
    {
        console.error("DocPreview NPAPI plugin failed to load");
    }
    toolbar.hide();
    return null;
    
}

function processDoc(request, uri, source_event)
{
    var doc = request.response;
    var html = doc2html(doc);
    //console.log(html);
    if (html)
    {
        var data_url = "data:text/html;base64," + UTF8ToBase64(html);
        safari.application.activeBrowserWindow.activeTab.url = data_url;
    }
    else
    {
        console.error("Failed to generate HTML representation");
    }
}

function handleRetrieveError(request, uri)
{
    var err_msg = "Failed to retrieve " + uri + " with code " + request.status;
    console.error(err_msg);
    alert(err_msg);
}

//function processClientRequest(msgEvent) {
//
//}

function handleContextMenu(event)
{
    if (!event.userInfo)
    {
        // not an actual click on somewhere we've detected
        return;
    }
    var mode = event.userInfo["mode"];
    var uri = event.userInfo["uri"];
    var doc_type = null;
    if (mode === "menu-add")
    {
        if (uri)
        {
            var test_uri = uri.toLowerCase();
            if (test_uri.endsWith(".doc") || test_uri.endsWith(".docx"))
            {
                doc_type = "Word";
            }
            else if (test_uri.endsWith(".rtf"))
            {
                doc_type = "RTF";
            }
            else if (test_uri.endsWith(".odf"))
            {
                doc_type = "OpenOffice";
            }
            if (doc_type)
                event.contextMenu.appendContextMenuItem("preview", "Preview this " + doc_type + " document");
//            else
//                console.info("Not a supported document type");
        }
//        else
//        {
//            console.info("Wasn't a click on a link");
//            console.info(event.target);
//        }
        
    }    
}


function performCommand(event) {
    var uri;
    var e = event;
    if (event.command === "preview")
    {
        uri = event.userInfo["uri"];
        console.log("retrieving from", uri);
        send_http_request(uri, {}, function(request, uri) { processDoc(request, uri, e);}, handleRetrieveError)
    }
   
}

function globalSetup()
{
    //safari.application.addEventListener("message",processClientRequest,false);
    safari.application.addEventListener("contextmenu", handleContextMenu, false);
    safari.application.addEventListener("command", performCommand, false);
    if (safari.extension.bars[0])
        safari.extension.bars[0].hide();
    var plugin = getDocPreviewPlugin();
    if (plugin)
    {
        if (plugin.version() !== pluginCompatibleVersion())
        {
            alert("Version mismatch between DocPreview2 NPAPI plugin and the Safari extension. Please redownload and reinstall DocPreview2.");
        }
        else
        {
            console.info("Version check passed");
        }
    }
    //safari.extension.settings.addEventListener("change", settingChange, false);
}