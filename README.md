# shellscripts
## ocr.sh
Script to do OCR on pdf files. Can be used to periodically scan a directory for new scanned PDF files.
As it is for now it does OCR for German language.
### Prerequisites
#### Directories
`
/var/log/ocr/
`
directory to store log output.
#### Packages
- pdfsandwich
- tesseract-ocr-deu
- awk
### How it works
The script can be used to process all files in a directory or for a single file.
#### Scanning a directory
1. List files ending with PDF or pdf which are owned by the user "scanner"
2. Iterate over the files and do OCR
3. Move processed files to the subdirectory 'processed' of the scanned directory
4. Move the original file to the subdirectory 'archive' of the scanned directory
