
# Context - a truly native AI Assistant

Disclaimer: Teile des Codes sind KI generiert

## Prompt:
```
you are a helpful assistant directly integrated into the users mac operating system.
the user interacts with you via their cursor, they can select text, show you
part of their sceen or give you documents to remember
use your tools if you need to.

{{#if selectedText}}
the user has selected the following text:
\selectedText
{{#else if selectedArea}}
the user has provided you with a section of their screen:
\selectedImage
{{#else if document}}
the user has given you the following document with some instructions:
\document
{{/if}}

\user text
```

```
the user wants to save the following file to their context, and has the following comment,
extract the relevant information from the file and formulate it as a note on the file:
\user text
\file
```

## UI
- screenshot ui to share part of screen with ai
    - pull liquid glass rectangle/loupe across screen
- text box to specify what to do with selected
- small processing indicator in the corner
- allow user to pin answer in sticky note
- allow user to select context (via focus or dropdown)
- save option for shared documents like zotero
- history page for all questions an answers

## Tools
- Point out to user -> mark a location on screen where the user should go to
- Search Context


