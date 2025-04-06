(defpackage "CL-T64"
  (:use "COMMON-LISP")
  (:export "TAPE-RECORD"
           "FILE-RECORD"
           "TAPE-IMAGE"
           "GET-FILE-CONTENTS"
           "GET-FILE-NAME"
           "READ-TAPE-RECORD"
           "READ-FILE-RECORDS"
           "GET-BINARY-CONTENT"
           "READ-TAPE-IMAGE"
           "WRITE-TAPE-IMAGE"
           "TAPE-RECORD-DETAILS"
           "FILE-RECORD-DETAILS"
           "TAPE-IMAGE-DETAILS"
           "ADD-FILE"
           "REMOVE-FILE"
           "NAME-FILE"
           "MOVE-FILES"
           "BLANK-TAPE")
)
(in-package "CL-T64")

; Tape record class
(defclass tape-record ()
  (
    (version :initarg :version)
    (directories :initarg :directories)
    (used-directories :initarg :used-directories)
  )
)

; File record class
(defclass file-record ()
  (
    (entry-type :initarg :entry-type)
    (file-type :initarg :file-type)
    (start-address :initarg :start-address)
    (end-address :initarg :end-address)
    (offset :initarg :offset)
    (file-name :initarg :file-name)
  )
)

; Tape image class
(defclass tape-image ()
  (
    (tape-record :initarg :tape-record)
    (file-records :initarg :file-records)
    (binary-content :initarg :binary-content)
  )
)

; Returns contents of filename as vector of bytes.
(defun get-file-contents (filename)
  (let ((thing (open filename :element-type '(unsigned-byte 8))) (content nil))
    (setf content (make-array (file-length thing) :fill-pointer (file-length thing) :element-type '(unsigned-byte 8)))
    (read-sequence content thing)
    content
  )
)

; Returns 16 byte file name from specified list/vector of bytes and offset.
(defun get-file-name (raw offset)
  (let ((i 0)(result ""))
    (loop
      (when (>= i 17) (return))
      (setf result (concatenate 'string result (list (code-char (elt raw (+ offset i))))))
      (incf i)
    )
    result
  )
)

; Returns tape record from specified image.
(defun read-tape-record (tape)
  (let (
         (raw (get-file-contents tape))
       )
      (make-instance 'tape-record
                    :version (+ (ash (elt raw 33) 8) (elt raw 32))
                    :directories (+ (ash (elt raw 35) 8) (elt raw 34))
                    :used-directories (+ (ash (elt raw 37) 8) (elt raw 36))
      )
  )
)

; Returns list of file records from specified image.
(defun read-file-records (tape)
  (let (
         (raw (get-file-contents tape))
         (tape-header (read-tape-record tape))
         (records (list 'list))
         (i 0)
       )
      (loop
        (when (>= i (slot-value tape-header 'used-directories))(return))
        (setf records (concatenate 'list records
                        (list (make-instance 'file-record
                                              :entry-type (elt raw (+ 64 (* i 32)))
                                              :file-type (elt raw (+ 65 (* i 32)))
                                              :start-address (+ (ash (elt raw (+ 67 (* i 32))) 8) (elt raw (+ 66 (* i 32))))
                                              :end-address (+ (ash (elt raw (+ 69 (* i 32))) 8) (elt raw (+ 68 (* i 32))))
                                              :offset (+ (ash (elt raw (+ 73 (* i 32))) 8) (elt raw (+ 72 (* i 32))))
                                              :file-name (get-file-name raw (+ 79 (* i 32)))

                        ))
                      )
        )
        (incf i)
      )
      (pop records)
      records
  )
)

; Returns 2D list containing the binary content of each file.
(defun get-binary-content (filename)
  (let ((file-records (read-file-records filename))(content (list 'list))(raw (get-file-contents filename)))
    (let ((i 0)(a 0)(file-size nil)(offset nil)(binary (list 'list)))
      (loop
        (when (>= i (length file-records))(return))
        (setf file-size (- (slot-value (elt file-records i) 'end-address) (slot-value (elt file-records i) 'start-address)))
        (setf offset (slot-value (elt file-records i) 'offset))
        (setf a offset)
        (loop
          (when (>= a (+ file-size offset))(return))
          (setf binary (concatenate 'list binary (list (elt raw a))))
          (incf a)
        )
        (incf i)
        (pop binary)
        (setf content (concatenate 'list content (list binary)))
        (setf binary (list 'list))
      )
    )
    (pop content)
    content
  )
)

; Returns tape image object from specified image.
(defun read-tape-image (tape)
  (let (
         (raw (get-file-contents tape))
       )
      (make-instance 'tape-image
                    :tape-record (read-tape-record tape)
                    :file-records (read-file-records tape)
                    :binary-content (get-binary-content tape)
      )
  )
)

; Writes tape image to destination as T64 file.
(defun write-tape-image (tape destination)
  (let ((output (open destination :direction :output :if-exists :supersede :if-does-not-exist :create :element-type '(unsigned-byte 8))))
    (let ((a 0)(o "C64 tape image file"))
      (loop
        (when (>= a (length o))(return))
        (write-byte (char-code (elt o a)) output)
        (incf a)
      )
    )
    (dotimes (list 13)
      (write-byte 0 output)
    )
    (write-byte (logand (slot-value (slot-value tape 'tape-record) 'version) #x00ff) output)
    (write-byte (ash (slot-value (slot-value tape 'tape-record) 'version) (- 0 8)) output)

    (write-byte (logand (slot-value (slot-value tape 'tape-record) 'directories) #x00ff) output)
    (write-byte (ash (slot-value (slot-value tape 'tape-record) 'directories) (- 0 8)) output)

    (write-byte (logand (slot-value (slot-value tape 'tape-record) 'used-directories) #x00ff) output)
    (write-byte (ash (slot-value (slot-value tape 'tape-record) 'used-directories) (- 0 8)) output)

    (write-byte 0 output)
    (write-byte 0 output)

    (dotimes (list 24)
      (write-byte 32 output)
    )

    (let ((i 0) (records (slot-value tape 'file-records)))
      (loop
        (when (>= i (length records))(return))
        (write-byte (slot-value (elt records i) 'entry-type) output)
        (write-byte (slot-value (elt records i) 'file-type) output)
        (write-byte (logand (slot-value (elt records i) 'start-address) #x0ff) output)
        (write-byte (ash (slot-value (elt records i) 'start-address) (- 0 8)) output)
        (write-byte (logand (slot-value (elt records i) 'end-address) #x0ff) output)
        (write-byte (ash (slot-value (elt records i) 'end-address) (- 0 8)) output)
        (write-byte 0 output)
        (write-byte 0 output)
        (write-byte (logand (slot-value (elt records i) 'offset) #x0ff) output)
        (write-byte (ash (slot-value (elt records i) 'offset) (- 0 8)) output)
        (write-byte 0 output)
        (write-byte 0 output)

        (write-byte 0 output)
        (write-byte 0 output)
        (write-byte 0 output)
        (write-byte 0 output)
        (let ((a 0)(o (slot-value (elt records i) 'file-name)))
          (loop
            (when (>= a 16)(return))
            (write-byte (char-code (elt o a)) output)
            (incf a)
          )
        )
        (incf i)
      )
    )

    (let ((a 0))
      (loop
        (when (>= a (length (slot-value tape 'binary-content)))(return))
        (let ((i 2) (content (elt (slot-value tape 'binary-content) a)))
          (loop
            (when (>= i (length content))(return))
            (write-byte (elt content i) output)
            (incf i)
          )
        )
        (incf a)
      )
    )

    (close output)
  )
)

; Prints details about specified tape record.
(defun tape-record-details (record)
  (format t "T64 VERSION: 0x~x~%" (slot-value record 'version))
  (format t "DIRECTORIES: ~d~%" (slot-value record 'directories))
  (format t "USED DIRECTORIES: ~d~%" (slot-value record 'used-directories))
  (terpri)
)

; Prints details about specified file record.
(defun file-record-details (record)
  (format t "ENTRY TYPE: ~x~%" (slot-value record 'entry-type))
  (format t "FILE TYPE: 0x~x~%" (slot-value record 'file-type))
  (format t "START ADDRESS: 0x~x~%" (slot-value record 'start-address))
  (format t "END ADDRESS: 0x~x~%" (slot-value record 'end-address))
  (format t "OFFSET: ~d~%" (slot-value record 'offset))
  (format t "FILE NAME: ~a~%" (slot-value record 'file-name))
  (terpri)
)

; Prints details about specified tape image.
(defun tape-image-details (tape)
  (tape-record-details (slot-value tape 'tape-record))
  (let ((i 0)(records (slot-value tape 'file-records)))
    (loop
      (when (>= i (slot-value (slot-value tape 'tape-record) 'used-directories))(return))
      (file-record-details (elt records i))
      (incf i)
    )
  )
)

; Adds file to tape and returns new tape.
(defun add-file (file tape name &optional (file-type #x82))
  (let ((the-tape tape) (binary file) (offset nil) (last-record nil))
    (incf (slot-value (slot-value the-tape 'tape-record) 'directories))
    (incf (slot-value (slot-value the-tape 'tape-record) 'used-directories))
    (when (not (equal (slot-value the-tape 'file-records) nil))
      (let ((i 0))
        (loop
          (when (>= i (length (slot-value the-tape 'file-records)))(return))
          (dotimes (list 32)
            (incf (slot-value (elt (slot-value the-tape 'file-records) i) 'offset))
          )
          (incf i)
        )
      )
      (setf last-record (elt (slot-value the-tape 'file-records) (- (length (slot-value the-tape 'file-records)) 1)))
      (setf offset (+ (slot-value last-record 'offset) (- (slot-value last-record 'end-address) (slot-value last-record 'start-address))))
    )
    (when (equal (slot-value the-tape 'file-records) nil)
      (setf offset 96)
    )
    (setf (slot-value the-tape 'file-records) (concatenate 'list (slot-value the-tape 'file-records)
                                                                 (list (make-instance 'file-record :entry-type 1
                                                                                             :file-type file-type
                                                                                             :start-address (+ (ash (elt binary 1) 8) (elt binary 0))
                                                                                             :end-address (+ (+ (ash (elt binary 1) 8) (elt binary 0)) (- (length binary) 2))
                                                                                             :offset offset
                                                                                             :file-name name))))
    (setf (slot-value the-tape 'binary-content) (concatenate 'list (slot-value the-tape 'binary-content) (list binary)))
    the-tape
  )
)

; Removes file from tape at specified index and returns new tape.
(defun remove-file (file-index tape)
  (let ((i 0)(the-tape (blank-tape)))
    (loop
      (when (>= i (length (slot-value tape 'file-records)))(return))
      (when (not (equal i file-index))
        (setf the-tape (add-file (elt (slot-value tape 'binary-content) i) the-tape (slot-value (elt (slot-value tape 'file-records) i) 'file-name)))
      )
      (incf i)
    )
    the-tape
  )
)

; Names file at specified index and returns new tape.
(defun name-file (file-index tape name)
  (let ((the-tape tape))
    (setf (slot-value (elt (slot-value the-tape 'file-records) file-index) 'file-name) name)
    the-tape
  )
)

; Swaps location of files at index1 and index2 and returns new tape.
(defun move-files (index1 index2 tape)
  (let ((i 0)(the-tape (blank-tape)))
    (decf (slot-value (slot-value the-tape 'tape-record) 'directories))
    (decf (slot-value (slot-value the-tape 'tape-record) 'used-directories))
    (loop
      (when (>= i (length (slot-value tape 'file-records)))(return))
      (when (and (not (equal i index1)) (not (equal i index2)))
        (setf the-tape (add-file (elt (slot-value tape 'binary-content) i) the-tape (slot-value (elt (slot-value tape 'file-records) i) 'file-name)))
      )
      (when (equal i index1)
        (setf the-tape (add-file (elt (slot-value tape 'binary-content) index2) the-tape (slot-value (elt (slot-value tape 'file-records) index2) 'file-name)))
      )
      (when (equal i index2)
        (setf the-tape (add-file (elt (slot-value tape 'binary-content) index1) the-tape (slot-value (elt (slot-value tape 'file-records) index1) 'file-name)))
      )
      (incf i)
    )
    the-tape
  )
)

; Returns new blank tape.
(defun blank-tape ()
  (let ((tape-record nil) (tape nil))
    (setf tape-record (make-instance 'tape-record :version #x100 :directories 0 :used-directories 0))
    (setf tape (make-instance 'tape-image :tape-record tape-record :file-records nil :binary-content nil))
    tape
  )
)
