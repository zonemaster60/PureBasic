; Hide folder
Procedure HideFolder(sFolder.s)
    Protected hFind = FindFirstFile_(sFolder + "\\*.*", @stFindData)
    If hFind
        Repeat
            If stFindData\cFileName <> "." And stFindData\cFileName <> ".."
                Protected sFile.s = sFolder + "\\" + stFindData\cFileName
                If stFindData\dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY
                    HideFolder(sFile)
                Else
                    Protected hFile = CreateFile_(sFile, GENERIC_READ Or GENERIC_WRITE, FILE_SHARE_READ Or FILE_SHARE_WRITE Or FILE_SHARE_DELETE, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL Or FILE_FLAG_BACKUP_SEMANTICS, 0)
                    If hFile <> INVALID_HANDLE_VALUE
                        Local dwBytesReturned
                        DeviceIoControl_(hFile, FSCTL_SET_REPARSE_POINT, @REPARSE_GUID_DATA_BUFFER, REPARSE_GUID_DATA_BUFFER_HEADER_SIZE + 2 + Len(sFile) + 2 + 4 + 2 + 4 + 2 + 4 + 2 + 4 + 2 + 4 + 2 + 4, @REPARSE_GUID_DATA_BUFFER, REPARSE_GUID_DATA_BUFFER_HEADER_SIZE + 8)
                        CloseHandle_(hFile)
                    EndIf
                EndIf
            EndIf
        Until Not FindNextFile_(hFind, @stFindData)
        FindClose_(hFind)
    EndIf
EndProcedure

; Example usage:
; HideFolder("C:\\Users\\User\\Desktop\\MyFolder")

; IDE Options = PureBasic 6.02 beta 2 LTS (Windows - x64)
; Folding = -
; EnableXP
; DPIAware