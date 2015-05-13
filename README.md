# DocPreview2

DocPreview2 is a Safari extension and NPAPI browser plugin to allow in-browser previews of Microsoft Word, RTF, and OpenOffice ODF documents.  It is available for OS X 10.10, and is tested on Safari 8.0.6.

DocPreview2 is the updated successor to the original [DocPreview](http://blog.yimingliu.com/2008/12/25/docpreview-plug-in-to-view-word/) that I wrote many years ago, which only worked on Safari 5.0 and earlier, and used a more powerful WebKit Plugin API that has since been removed from Safari.

## Download
Source code is available at [https://github.com/yimingliu/docpreview2](https://github.com/yimingliu/docpreview2)

Precompiled binaries are available at [https://github.com/yimingliu/docpreview2/releases](https://github.com/yimingliu/docpreview2/releases)

## Installation
If building from source, simply build the DocPreview2 project in Xcode (it should automatically install the NPAPI plugin in the proper directory on successful build), and then install the corresponding Safari extension using Safari's built-in Extension Builder.  Note installing the Safari extension from Extension Builder will require setting up a (free) Apple Safari Developer certificate.

If using the precompiled binary, simply drop DocPreview2.plugin into `~/Library/Internet Plug-Ins` and then install the .safariextension by double-clicking the .safariextz bundle.  Note the `~/Library` directory is invisible by default on OS X Yosemite.  Users who have not removed the invisible flag on `~/Library` will need to use `Go -> Go to Folder` from the Finder menu bar to get to the directory.

## Usage
Right-click a URI on any web page that links to a .doc, .docx, .rtf, or .odf file.  The option `Preview this [doc_type] document` will appear in the contextual menu that pops up.  Select that option to generate a HTML preview of the document within the browser.

Left-clicking the URI would download the document, as normal.

### Updates
Due to the nature of this extension, which requires both a .plugin component and an extension, users will need to return to this page to download future updates.

The two components must be of the same version for proper functionality.  If there is a version mismatch, please download/rebuild the latest version from this repository.

###Technical notes

- In the original DocPreview, clicking on the link itself would generate a HTML representation of the document within the browser window, and right-clicking the link/selecting from a menu would allow a download of the document.  This behavior is reversed in DocPreview2, because implementing the original behavior is far more technically challenging (this is why I was not able to update DocPreview for years, as I tried in vain to figure out how to do this).  Despite the original behavior being more user-friendly, the current model allows much more trivial implementation of the same functionality.

- DocPreview2 is unable to provide in-page, embedded viewing for .doc files.  No one was using this functionality anyway.  It was more of an experiment in the first version, to see how such things worked.

- I am fully aware that detecting compatible content should be done via MIME type in the HTTP response header, rather than parsing for filetype extensions in URI.  Media types are the true way of how the Web handles file types. However,
  * To know whether a link pointed to a compatible file using the MIME type, the extension would have to make an extra request first to that URI, either HEAD or a full GET.
  * It is unclear whether a user would be happy with such a design. To me, right-clicking a link to open a context menu should not trigger any network activity.
  * Without making the extra request, the NPAPI plugin would have to handle doc mimetypes directly, by itself.  The problem with this is the same as in the first point in this section: it is technically challenging to attempt to render the converted HTML representation onto the browser, in a useful form, using only NPAPI.


## Caveats

- DocPreview2 only supports OS X and the Safari browser.

- I make no guarantees as to the usefulness of DocPreview2 for anyone else other than myself.  YMMV.  The entire package is open source.  I will gladly take pull requests when things need fixing.

- NPAPI is a deprecated technology.  Google Chrome does not implement NPAPI since version 42.  Firefox is in the process of removing support.  There is no point trying to make a NPAPI extension for these browsers.  Safari has not yet announced deprecation of NPAPI, but I'm sure it will be coming.  
  * If Apple still has not improved desktop Safari to make these preview renderings within the browser, I would need to find a new way to write DocPreview 3.  Presumably via some kind of pure Javascript parser for these files.

- It is really odd that iOS has had native in-browser preview rendering for doc, xls, etc. for many years now, within MobileSafari.  Why has this feature not come to desktop Safari?  It seems like it would be trivial to backport the technology to Safari's more capable desktop incarnation.


