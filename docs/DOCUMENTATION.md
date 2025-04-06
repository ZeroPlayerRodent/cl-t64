# Documentation

## Class:
TAPE-RECORD

### Slots:
- VERSION (byte)
- DIRECTORIES (byte)
- USED-DIRECTORIES (byte)

## Class:
FILE-RECORD

### Slots:
- ENTRY-TYPE (byte)
- FILE-TYPE (byte)
- START-ADDRESS (word)
- END-ADDRESS (word)
- OFFSET (word)
- FILE-NAME (string)

## Class:
TAPE-IMAGE

### Slots:
- TAPE-RECORD (tape-record)
- FILE-RECORDS (list of file-records)
- BINARY-CONTENT (2D list of bytes)

## Function:
GET-FILE-CONTENTS

### Arguments:
- FILENAME (string)

### Description:
Opens file FILENAME and returns binary content of file as vector.

## Function:
GET-FILE-NAME

### Arguments:
- RAW (list of bytes)
- OFFSET (integer)

### Description:
Returns 16-byte file name located at OFFSET in RAW.

## Function:
READ-TAPE-RECORD

### Arguments:
- TAPE (string)

### Description:
Opens T64 file named TAPE and returns tape record.

## Function:
READ-FILE-RECORDS

### Arguments:
- TAPE (string)

### Description:
Opens T64 file named TAPE and returns list of file records.

## Function:
GET-BINARY-CONTENT

### Arguments:
- FILENAME (string)

### Description:
Opens T64 file named FILENAME and returns 2D list of binary content.

## Function:
READ-TAPE-IMAGE

### Arguments:
- TAPE (string)

### Description:
Opens T64 file named TAPE and returns tape-image.

## Function:
WRITE-TAPE-IMAGE

### Arguments
- TAPE (tape-image)
- DESTINATION (string)

### Description:
Writes TAPE to DESTINATION as T64 file.

## Function:
TAPE-RECORD-DETAILS

### Arguments:
- RECORD (tape-record)

### Description:
Outputs information about RECORD.

## Function:
FILE-RECORD-DETAILS

### Arguments:
- RECORD (file-record)

### Description:
Output information about RECORD.

## Function:
TAPE-IMAGE-DETAILS

### Arguments:
- TAPE (tape-image)

### Description:
Output information about TAPE.

## Function:
ADD-FILE

### Arguments:
- FILE (list/vector of bytes)
- TAPE (tape-image)
- NAME (string)

### Optional Arguments:
- FILE-TYPE (word, defaults as `#x82`)

### Description:
Returns TAPE with binary content of FILE added as NAME with file type of FILE-TYPE.

## Function:
REMOVE-FILE

### Arguments:
- FILE-INDEX (integer)
- TAPE (tape-image)

### Description
Returns TAPE without file at FILE-INDEX.

## Function:
NAME-FILE

### Arguments:
- FILE-INDEX (integer)
- TAPE (tape-image)
- NAME (string)

### Description:
Returns TAPE with file at FILE-INDEX named NAME.

## Function:
MOVE-FILES

### Arguments:
- INDEX1 (integer)
- INDEX2 (integer)
- TAPE (tape-image)

### Description:
Returns TAPE with files at INDEX1 and INDEX2 swapped.

## Function:
BLANK-TAPE

### Description:
Returns blank tape-image.
