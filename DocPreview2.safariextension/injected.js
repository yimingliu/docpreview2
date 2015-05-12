//function handleExtensionMessage(msg_event) {
//    
//    if (window.top === window)
//    {
//        if (msg_event.name === "html_output")
//        {
//
//        }
//    }
//    
//}

function extractURI(target)
{
    
    if (target.nodeName === "A")
    {
        return target.href;
    }
    return null;
}



function handleContextMenu(event) {
    var uri = extractURI(event.target);
    safari.self.tab.setContextMenuEventUserInfo(event, {"mode":"menu-add", "uri":uri});
}

function injectedSetup()
{
    document.addEventListener("contextmenu", handleContextMenu, false);
    //safari.self.addEventListener("message", handleExtensionMessage, false);
}

if (window.top === window)
{
    injectedSetup();
}