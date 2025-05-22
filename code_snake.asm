.model small              ; Su dung mo hinh bo nho small (code va data rieng biet)
.stack 200h               ; Cap phat ngan xep kich thuoc 512 byte

.data                     ; Bat dau khai bao du lieu

	; Cau hinh hien thi 
	backgroud_color equ 60h        ; Mau nen cua man hinh
	player_score_color equ 0Fh     ; Mau chu hien thi diem (trang sang)
	screen_width equ 80d           ; Do rong man hinh van ban (80 cot)
	screen_hight equ 25d           ; Do cao man hinh van ban (25 dong)
	border_color equ 17h           ; Mau vien cua khung choi

	; Du lieu diem so nguoi choi 
	player_score_label_offset equ 0 ; Do lech hien thi nhan diem
	player_score db 0               ; Bien luu diem hien tai cua nguoi choi
	player_win_score equ 100        ; Diem de chien thang game
    msg_score db 'SCORE: $'         ; Chuoi hien thi "SCORE:"
    score1 db '000$'                ; Chuoi luu diem hien tai duoi dang text

	; Du lieu con ran 
	snake_len dw ?                         ; Do dai hien tai cua ran
	snake_body dw player_win_score + 3h dup(?) ; Mang luu toa do tung phan than ran
	snake_previous_last_cell dw ?         ; O cuoi cua ran truoc do de ve lai nen

	; Du lieu di chuyen 
	RIGHT equ 4Dh       ; Ma phim mui ten phai
	LEFT equ 4Bh        ; Ma phim mui ten trai
	UP equ 48h          ; Ma phim mui ten len
	DOWN equ 50h        ; Ma phim mui ten xuong
	snake_direction db ? ; Huong di chuyen hien tai cua ran

	; Du lieu thuc an 
	food_location dw ?             ; Vi tri hien tai cua thuc an
	food_color equ 64h             ; Mau cua thuc an
	food_icon equ 14               ; Ky tu bieu tuong cua thuc an
	food_bounders equ 2d*screen_width*2d ; Gioi han vung xuat hien cua thuc an

	; Trang thai tro choi 
	EXIT db 0h                     ; Co de thoat game
	START_AGAIN db 0h             ; Co de bat dau lai game
	START_AGAIN_KEY equ 39h       ; Ma phim SPACE (phim cach)
	END_GAME_KEY equ 01h          ; Ma phim ESC (thoat game)

	; Thong diep ket thuc game 
	msg_game_over db 'GAME OVER!: ( You have hit a dead end. Try again! )', 0Ah, 0Dh, '$'
	msg_game_over2 db '                          PRESS SPACE TO START AGAIN', 0Ah, 0Dh, '$'   
	msg_game_over1 db 'PRESS Esc TO EXIT', 0Ah, 0Dh, '$'
	msg_game_win db '           YOU HAVE WON THE GAME !!:)  PRESS ANY KEY TO EXIT', 0Ah, 0Dh, '$'     

	; Giao dien menu chinh 
    main1 db "Snake Game"                     ; Tieu de game
    main2 db "WELCOME TO SNAKE GAME! enjoy:)" ; Loi chao mung
    main3 db "In this game you must eat 100 to win:" ; Muc tieu cua tro choi
    main4 db "Move the snake by pressing the keys:",30," ",31," ",16," ",17 ; Huong dan dieu khien bang phim
    main5 db 30,":move up"                   ; Di len
    main6 db 31,":move down"                 ; Di xuong
    main7 db 16,":move right"                ; Di phai
    main8 db 17,":move left"                 ; Di trai
    about1 db "This game is done by: Team 6" ; Ten nhom thuc hien
    about2 db "To the computer architecture couse" ; Mon hoc thuc hien game
    main9 db "PRESS THE Esc KEY TO EXIT THE GAME." ; Thoat khoi tro choi
    main10 db "Press any key to start..."    ; Huong dan bat dau tro choi

.code
MAIN:
	; Khoi tao segment du lieu
	mov ax, @data           ; Lay dia chi segment data
    mov ds, ax              ; Gan vao thanh ghi DS
	
	call INIT_GAME       ; Goi ham khoi tao game
	call main_menu       ; Goi menu chinh
	
	; Vong lap chinh cua tro choi
	MAIN_LOOP:	
		call MOVE_SNAKE               ; Di chuyen con ran
		call PRINT_SNAKE              ; Ve lai ran len man hinh
		call CHECK_SNAKE_AET_FOOD     ; Kiem tra ran an thuc an chua
		call CHECK_SNAKE_IN_BORDERS   ; Kiem tra ran co cham bien khong
		call CHECK_SNAKE_NOOSE        ; Kiem tra ran co tu an minh khong
		call GET_DIRECTION_BY_KEY     ; Lay huong di tu ban phim
		call MAIN_LOOP_FRAME_RATE     ; Dieu chinh toc do vong lap

		; Neu bien EXIT = 1 thi thoat game
		cmp [EXIT], 1h
		jnz MAIN_LOOP                ; Neu chua thi lap tiep

	; Neu muon choi lai thi quay ve MAIN
	cmp [START_AGAIN],1h
	jz MAIN

	call INIT_SCREEN_BACK_TO_OS    ; Khoi tao man hinh ve trang thai ban dau
	mov ah,4ch                     ; Thoat ve DOS
	int 21h

; Ham khoi tao game
INIT_GAME proc near
	mov byte ptr [player_score],0h               ; Dat diem nguoi choi bang 0
	mov byte ptr [snake_direction],RIGHT         ; Khoi tao huong di cua ran la sang phai
	mov word ptr [snake_previous_last_cell],screen_width*screen_hight*2d ; Gan vi tri cuoi ran (tam thoi)
	mov word ptr [food_location],8d*screen_width*2d + 10d*2d ; Dat vi tri thuc an ban dau
	mov byte ptr [EXIT],0h                       ; Dat co thoat bang 0
	mov byte ptr [START_AGAIN],0h                ; Dat co choi lai bang 0

	call INIT_SCREEN                             ; Goi thu tuc khoi tao man hinh
	call INIT_SNAKE_BODY                         ; Goi thu tuc khoi tao than ran

	ret                                          ; Ket thuc thu tuc
INIT_GAME endp



; Kiem tra ran tu an minh (cham vao than)
CHECK_SNAKE_NOOSE proc near
    push si                   ; Luu thanh ghi SI vao stack
    push ax                   ; Luu thanh ghi AX vao stack

    mov ax, snake_body[0h]    ; AX = vi tri dau ran (phan tu dau cua mang snake_body)
    mov si, 2h                ; SI = 2 (bat dau tu khoi thu hai cua ran)

CHECK_SNAKE_NOOSE_LOOP:
    cmp ax, snake_body[si]    ; So sanh vi tri dau voi tung phan cua than
    jz CHECK_SNAKE_NOOSE_GAME_OVER ; Neu trung thi goi GAME_OVER

    add si, 2h                ; Di den phan than tiep theo (vi moi phan tu chiem 2 byte)
    cmp si, snake_len         ; Kiem tra da het do dai ran chua
    jnz CHECK_SNAKE_NOOSE_LOOP ; Neu chua thi lap lai

    jmp END_CHECK_SNAKE_NOOSE ; Khong bi tu cham thi nhay den ket thuc

CHECK_SNAKE_NOOSE_GAME_OVER:
    call GAME_OVER            ; Goi ham ket thuc game

END_CHECK_SNAKE_NOOSE:
    pop ax                    ; Khoi phuc AX
    pop si                    ; Khoi phuc SI
    ret
CHECK_SNAKE_NOOSE endp


; Kiem tra ran cham vien man hinh
CHECK_SNAKE_IN_BORDERS proc near
	push ax                        ; Luu AX
	push bx                        ; Luu BX
	push dx                        ; Luu DX

	mov ax, snake_body[0h]         ; Lay vi tri dau ran

	; Kiem tra bien tren (dong 2)
	cmp ax, 2d*screen_width*2d     ; Neu nho hon thi cham bien tren
	jb CHECK_SNAKE_IN_BORDERS_GAME_OVER

	; Kiem tra bien duoi (dong 24)
	cmp ax, 24d*screen_width*2d    ; Neu lon hon hoac bang thi cham bien duoi
	jae CHECK_SNAKE_IN_BORDERS_GAME_OVER

	; Kiem tra bien trai va phai
	mov bx, screen_width*2d        ; Moi dong co 160 byte
	xor dx, dx                     ; Xoa dx de chuan bi chia
	div bx                         ; ax = so dong, dx = vi tri cot
	cmp dx, 0                      ; Neu dx = 0 thi cham bien trai
	je CHECK_SNAKE_IN_BORDERS_GAME_OVER
	cmp dx, 79d*2d                 ; Neu dx >= 158 thi cham bien phai
	jae CHECK_SNAKE_IN_BORDERS_GAME_OVER

	jmp CHECK_SNAKE_IN_BORDERS_VALID ; Neu an toan thi tiep tuc

CHECK_SNAKE_IN_BORDERS_GAME_OVER:
	call GAME_OVER                 ; Goi thu tuc ket thuc game

CHECK_SNAKE_IN_BORDERS_VALID:
	pop dx                         ; Khoi phuc DX
	pop bx                         ; Khoi phuc BX
	pop ax                         ; Khoi phuc AX
	ret                            ; Ket thuc thu tuc
CHECK_SNAKE_IN_BORDERS endp


; Kiem tra ran an thuc an
CHECK_SNAKE_AET_FOOD proc near
    push ax                    ; Luu gia tri cua thanh ghi AX vao stack de giu nguyen gia tri cu
    push si                    ; Luu thanh ghi SI vao stack

    mov ax, snake_body[0h]     ; AX = vi tri hien tai cua dau ran (phan tu dau tien trong mang snake_body)
    cmp ax, food_location      ; So sanh vi tri dau ran voi vi tri thuc an
    jnz END_CHECK_SNAKE_AET_FOOD ; Neu khong bang (ran chua an) thi nhay den ket thuc ham

    ; Neu dau ran trung voi vi tri thuc an -> da an thuc an
    call GENERATE_RANDOM_FOOD_LOCATION ; Goi ham tao vi tri thuc an moi

    mov si, [food_location]    ; SI = dia chi moi cua thuc an vua tao
    mov al, food_icon          ; AL = ky tu hien thi cua thuc an (vi du: dau '*')
    mov ah, food_color         ; AH = mau cua thuc an
    mov es:[si], ax            ; Ghi thong tin thuc an (ky tu + mau) vao bo nho video (vi tri SI trong segment ES)

    ; Keo dai do dai cua ran
    mov ax, [snake_previous_last_cell] ; AX = vi tri cuoi cung cua ran o khung truoc
    mov si, [snake_len]                ; SI = do dai hien tai cua ran (theo byte)
    mov snake_body[si], ax             ; Them vi tri cuoi vao cuoi mang snake_body de keo dai ran
    add [snake_len], 2d                ; Tang do dai cua ran them 2 byte (1 toa do moi)

    ; Tang diem cho nguoi choi
    inc byte ptr [player_score]        ; Tang bien player_score len 1

    call PRINT_PLAYER_SCORE            ; Goi ham cap nhat va hien thi diem tren man hinh

    ; Kiem tra xem da dat diem toi da de thang chua
    cmp byte ptr [player_score], player_win_score ; So sanh diem hien tai voi diem thang
    jnz END_CHECK_SNAKE_AET_FOOD       ; Neu chua bang thi ket thuc ham (chua thang)

    call WIN_GAME                      ; Neu bang diem thang -> goi ham chien thang

END_CHECK_SNAKE_AET_FOOD:
    pop si                             ; Khoi phuc thanh ghi SI tu stack
    pop ax                             ; Khoi phuc thanh ghi AX tu stack
    ret                                ; Quay ve vi tri goi ham
CHECK_SNAKE_AET_FOOD endp

; Tao vi tri ngau nhien hop le cho thuc an tren man hinh				
GENERATE_RANDOM_FOOD_LOCATION proc near
    push ax          ; Luu AX vao stack
    push bx          ; Luu BX vao stack
    push cx          ; Luu CX vao stack
    push dx          ; Luu DX vao stack
    push si          ; Luu SI vao stack

GENERATE_RANDOM_FOOD_LOCATION_RETRY:
    ; Lay thoi gian he thong lam nguon ngau nhien
    mov ah, 0h
    int 1Ah          ; Goi ngat 1Ah de lay so tick tu luc nua dem (CX:DX)
    mov ax, dx       ; Lay phan DX (phan thap) lam gia tri ngau nhien cho dong

    ; Tinh dong ngau nhien tu 2 den 23 (vi dong 0-1 va 24 khong dung cho thuc an)
    mov bx, 22d      ; Co 22 dong hop le (2..23)
    xor dx, dx       ; Xoa DX de chia khong bi sai
    div bx           ; AX chia BX, DX = so du, trong khoang 0..21
    add dx, 2        ; Chuyen thanh khoang 2..23
    mov cx, dx       ; CX = so dong chon duoc

    ; Tinh offset cua dong do trong bo nho video (160 byte / dong)
    mov ax, screen_width * 2d ; AX = 160
    mul cx           ; AX = offset dong (dong * 160)
    mov bx, ax       ; BX = offset dong

    ; Tiep tuc tao so ngau nhien de chon cot
    mov ah, 0h
    int 1Ah          ; Lay lai so tick he thong
    mov ax, dx       ; AX = tick ngau nhien
    mov dx, 0
    mov cx, 78d      ; 78 cot hop le (1..78)
    div cx           ; DX = cot tuong doi (0..77)
    inc dx           ; Tang len 1 -> khoang 1..78
    shl dx, 1        ; Nhan 2 vi moi vi tri 2 byte (ky tu + mau)
    add bx, dx       ; BX = offset toan bo (dong + cot)

    ; Kiem tra xem BX co nam trong khu vuc hop le khong
    cmp bx, 322d     ; Toa do nho nhat hop le (dong 2, cot 1)
    jb GENERATE_RANDOM_FOOD_LOCATION_RETRY ; Neu nho hon -> thu lai
    cmp bx, 3836d    ; Toa do lon nhat hop le (dong 23, cot 78)
    ja GENERATE_RANDOM_FOOD_LOCATION_RETRY ; Neu lon hon -> thu lai

    ; Kiem tra thuc an co trung voi vi tri cua than ran khong
    mov si, 0d       ; Bat dau tu dau danh sach than ran
CHECK_SNAKE_OVERLAP:
    cmp bx, snake_body[si]     ; So sanh vi tri thuc an voi tung doan than ran
    je GENERATE_RANDOM_FOOD_LOCATION_RETRY ; Neu trung thi thu lai
    add si, 2d                 ; Di chuyen den vi tri than ran tiep theo
    cmp si, [snake_len]        ; Kiem tra da duyet het than ran chua
    jnz CHECK_SNAKE_OVERLAP    ; Neu chua thi tiep tuc

    ; Neu da qua tat ca va khong trung, luu vi tri thuc an
    mov [food_location], bx    ; Ghi vi tri thuc an vao bien food_location

    ; Khoi phuc cac thanh ghi da day vao stack
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret                        ; Ket thuc ham
GENERATE_RANDOM_FOOD_LOCATION endp

; Dieu chinh toc do chay cua game				
MAIN_LOOP_FRAME_RATE proc near
    push ax          ; Luu thanh ghi AX vao stack
    push cx          ; Luu thanh ghi CX vao stack
    push dx          ; Luu thanh ghi DX vao stack
    push bx          ; Luu thanh ghi BX vao stack

    ; Lay diem nguoi choi vao thanh ghi BX
    mov bx,0h
    mov bl,[player_score] ; Lay diem hien tai vao BL

    mov cl,4d       ; CL = 4, dung de dich phai 4 bit (chia cho 16)
    shr bx,cl       ; BX = BX >> 4, giam toc do delay theo diem

    ; Cau hinh cho ham delay int 15h, ah=86h: delay cx:dx micro giay
    mov al,0        ; AL = 0, khong dung trong truong hop nay
    mov ah,86h      ; AH = 86h, ma lenh delay trong BIOS (int 15h)

    mov cx,0000h    ; CX = 0, phan cao cua thoi gian delay
    mov dx,0FFFFh   ; DX = 65535 (gia tri max)

    sub dx,bx       ; Giam thoi gian delay theo diem nguoi choi (diem cao = delay nho hon)

    int 15h         ; Goi ngat BIOS de delay theo thoi gian cau hinh

    pop bx          ; Phuc hoi thanh ghi BX
    pop dx          ; Phuc hoi thanh ghi DX
    pop cx          ; Phuc hoi thanh ghi CX
    pop ax          ; Phuc hoi thanh ghi AX

    ret             ; Tra ve
MAIN_LOOP_FRAME_RATE endp

.
; Hien thong bao chien thang, nhap phim bat ky de thoat game.
WIN_GAME proc near 
    push dx            ; Luu thanh ghi DX vao stack
    push ax            ; Luu thanh ghi AX vao stack
    push bx            ; Luu thanh ghi BX vao stack

    ; Dat con tro ve vi tri dong 18, cot 0 (trung tam tuong doi tren man hinh)
    mov ah, 02h        ; Ham dat vi tri con tro (int 10h)
    mov bh, 0          ; Trang man hinh so 0
    mov dh, 12         ; Dong 18 (12h = 18)
    mov dl, 0          ; Cot 0
    int 10h            ; Goi ngat video BIOS

    ; Bat dau to mau nhap nhay mot dong giua man hinh de lam hieu ung thang game
    mov bx, 0h         ; BX se dung de duyet qua cac o tren dong 12
GAME_WIN_BLINK_LABEL:
    mov ax, 0h         
    mov ah, backgroud_color   ; Mau nen da dinh nghia tu truoc (60h)
    or ah, 10000000b          ; Bat bit nhap nhay (blink bit) trong thuoc tinh ky tu
    ; Ghi thuoc tinh + ky tu vao dong 12 cua man hinh (dong 12*width*2 = offset)
    mov es:[bx + 12*screen_width*2d], ax 
    add bx, 2h                ; Tang BX len 2 vi moi ky tu man hinh chiem 2 byte
    cmp bx, screen_width*2d  ; Kiem tra het 1 dong chua
    jnz GAME_WIN_BLINK_LABEL ; Neu chua het thi lap tiep

    ; Hien thong bao chien thang
    mov dx, offset msg_game_win ; DX tro den chuoi thong bao chien thang
    mov ah, 9h                  ; Ham in chuoi ket thuc bang '$' (int 21h)
    int 21h                     ; In chuoi ra man hinh

    ; Doi nguoi choi bam phim bat ky
    mov ax, 0h
    mov ah, 0h
    int 16h             ; Goi ham cho bam phim (keyboard interrupt)

    ; Xoa bo dem phim
    mov ah, 0Ch
    int 21h             ; Clear keyboard buffer (DOS)

    ; Dat bien EXIT = 1 de ket thuc vong lap chinh cua game
    mov byte ptr [EXIT], 1h

    pop ax              ; Phuc hoi AX
    pop dx              ; Phuc hoi DX
    ret                 ; Tra ve
WIN_GAME endp

; Hien thong bao "GAME OVER"
GAME_OVER proc near 
    push dx          ; Luu DX vao stack
    push ax          ; Luu AX vao stack
    push bx          ; Luu BX vao stack

    ; Dat con tro den vi tri dong 18 (12h), cot 15 de in thong bao
    mov ah, 02h      
    mov bh, 0        ; Man hinh so 0
    mov dh, 12       ; Dong 18
    mov dl, 15       ; Cot 15
    int 10h          ; Goi BIOS ngat de dat vi tri con tro

    ; In thong bao GAME OVER
    mov dx, offset msg_game_over ; Chuoi thong bao "GAME OVER"
    mov ah, 9h                   ; Ham in chuoi ket thuc bang '$'
    int 21h                      ; Goi ngat DOS

    ; Dat con tro xuong dong tiep theo de lam hieu ung nhap nhay
    mov ah, 02h
    mov bh, 0
    mov dh, 14       ; Dong 20
    mov dl, 0        ; Cot 0
    int 10h

    mov bx, 0h       ; BX se duyet qua tung o trong dong 14

GAME_OVER_BLINK_LABEL:
    mov ax, 0h
    mov ah, backgroud_color      ; Mau nen dinh nghia truoc
    or ah, 10000000b             ; Bat che do nhap nhay
    mov es:[bx + 14*screen_width*2d], ax ; Ghi vao dong 14
    add bx, 2h                   ; Moi ky tu man hinh la 2 byte
    cmp bx, screen_width*2d      ; Da ghi het 1 dong chua
    jnz GAME_OVER_BLINK_LABEL    ; Neu chua thi lap tiep

    ; In thong bao phu (msg_game_over2)
    mov dx, offset msg_game_over2
    mov ah, 9h
    int 21h

    ; In thong bao huong dan bam phim (msg_game_over1)
    mov ah, 02h
    mov bh, 0
    mov dh, 16       ; Dong 22
    mov dl, 30       ; Cot 30
    int 10h

    mov dx, offset msg_game_over1
    mov ah, 9h
    int 21h

GAME_OVER_GET_OTHER_KEY:
    ; Xoa bo dem phim
    mov ah, 0Ch
    int 21h

    ; Cho nguoi dung bam phim
    mov ax, 0h
    mov ah, 0h
    int 16h          ; Lay phim tu ban phim

    ; Neu bam phim END_GAME_KEY thi ket thuc
    cmp ah, END_GAME_KEY
    jz END_GAME_OVER

    ; Neu bam phim START_AGAIN_KEY thi choi lai
    cmp ah, START_AGAIN_KEY
    jz GAME_OVER_START_AGAIN

    ; Nguoc lai, tiep tuc cho bam phim lai
    jmp GAME_OVER_GET_OTHER_KEY

GAME_OVER_START_AGAIN:
    mov [START_AGAIN], 1h    ; Dat co de bat dau lai game

END_GAME_OVER:
    ; Xoa bo dem phim lan nua
    mov ah, 0Ch
    int 21h

    mov byte ptr [EXIT], 1h  ; Ket thuc game

    pop bx
    pop ax
    pop dx
    ret
GAME_OVER endp

; Cap nhat vi tri moi cua dau ran va di chuyen toan bo than ran theo huong hien tai.
MOVE_SNAKE proc near
    push ax          ; Luu thanh ghi AX
    push bx          ; Luu thanh ghi BX

    ; Luu lai o cuoi cung cua ran truoc khi di chuyen (de sua background sau nay)
    mov bx, snake_len                ; BX = do dai ran
    mov ax, snake_body[bx - 2d]      ; AX = toa do o cuoi cung cua ran (truoc khi di chuyen)
    mov [snake_previous_last_cell], ax ; Luu vao bien tam snake_previous_last_cell

    ; Lay vi tri dau ran (snake_body[0]) vao AX
    mov ax, snake_body[0h]
    ; Goi ham SHR_ARRAY de dich toan bo mang snake_body xuong mot vi tri (shift mang xuong)
    call SHR_ARRAY

    ; Kiem tra huong di chuyen hien tai va tinh toa do moi cho dau ran
    ; Neu huong la RIGHT thi nhay den MOVE_RIGHT
    cmp byte ptr [snake_direction], RIGHT
    jz MOVE_RIGHT
    ; Neu huong la LEFT thi nhay den MOVE_LEFT
    cmp byte ptr [snake_direction], LEFT
    jz MOVE_LEFT
    ; Neu huong la UP thi nhay den MOVE_UP
    cmp byte ptr [snake_direction], UP
    jz MOVE_UP
    ; Neu huong la DOWN thi nhay den MOVE_DOWN
    cmp byte ptr [snake_direction], DOWN
    jz MOVE_DOWN

MOVE_RIGHT:
    add ax, 2d       ; Tang toa do cot len 2 byte (di chuyen sang phai)
    jmp MOVE_TO_DIRECTION

MOVE_LEFT:
    sub ax, 2d       ; Giam toa do cot 2 byte (di chuyen sang trai)
    jmp MOVE_TO_DIRECTION

MOVE_UP:
    sub ax, screen_width*2d  ; Giam toa do dong (di chuyen len tren)
    jmp MOVE_TO_DIRECTION

MOVE_DOWN:
    add ax, screen_width*2d  ; Tang toa do dong (di chuyen xuong duoi)
    jmp MOVE_TO_DIRECTION

MOVE_TO_DIRECTION:
    ; Cap nhat lai vi tri moi cua dau ran vao snake_body[0]
    mov snake_body[0h], ax

    pop bx           ; Phuc hoi BX
    pop ax           ; Phuc hoi AX
    ret
MOVE_SNAKE endp

				
; Hien thi con ran tren man hinh do hoa 
PRINT_SNAKE proc near
    push ax          ; Luu gia tri thanh ghi AX
    push si          ; Luu gia tri thanh ghi SI (chi so vong lap)
    push bx          ; Luu gia tri thanh ghi BX

    ; SUA LAI BACKGROUND o vi tri cuoi cung cua ran (cell cu da bi ran chiem)
    mov bx, [snake_previous_last_cell] ; BX = toa do cell cuoi truoc do
    mov al, 0h                          ; AL = ky tu trong (hoac NULL)
    mov ah, backgroud_color            ; AH = mau nen (duoc dinh nghia san)
    mov es:[bx], ax                    ; Ghi lai du lieu vao vi tri cu trong bo nho man hinh

    ; IN DAU RAN
    mov al, 'O'       ; AL = ky tu 'O' de the hien dau ran
    mov ah, 0Eh       ; AH = mau cua dau ran (0Eh thuong la vang nhat)
    mov bx, snake_body[0d] ; BX = toa do cua dau ran
    mov es:[bx], ax   ; Ghi ky tu 'O' vao vi tri cua dau ran

    ; KIEM TRA NEU RAN CHI CO DAU (khong co than) thi nhay den ket thuc
    cmp snake_len, 2h  ; Neu do dai ran <= 2 thi khong in than
    jz END_PRINT_SNAKE ; Nhay den cuoi ham neu dung

    ; IN THAN RAN
    ; Dat mau than ran
    mov al, 4         ; AL = ky tu hien thi (4 co the la ky tu tren bang ma ASCII)
    mov ah, 0Eh       ; AH = mau than ran

    ; Bat dau in tu vi tri thu 2 (chi so 2, vi 0 la dau ran, 1 la da bo qua)
    mov si, 2h

PRINT_SNAKE_LOOP:
    mov bx, snake_body[si] ; BX = toa do cua phan than ran tai vi tri SI
    mov es:[bx], ax        ; In ky tu than ran vao vi tri tuong ung

    add si, 2h             ; Tang SI len 2 byte (vi moi phan tu la 2 byte)
    cmp si, [snake_len]    ; Kiem tra xem da het do dai ran chua
    jnz PRINT_SNAKE_LOOP   ; Neu chua het thi lap tiep

END_PRINT_SNAKE:
    pop bx           ; Phuc hoi BX
    pop si           ; Phuc hoi SI
    pop ax           ; Phuc hoi AX
    ret              ; Ket thuc ham
PRINT_SNAKE endp


; Hien thi diem cua nguoi choi len man hinh tai vi tri (0,0)
PRINT_PLAYER_SCORE proc near

    ; Dat con tro chuot ve vi tri (dong 0, cot 0) tren man hinh 
    mov ah, 02h       ; Ham 02h cua ngat 10h: dat vi tri con tro
    mov bh, 0         ; Trang man hinh so 0
    mov dh, 0         ; Dong 0
    mov dl, 0         ; Cot 0
    int 10h           ; Goi ngat BIOS de di chuyen con tro

    ; Hien thi chu "Score: " 
    mov dx, offset msg_score ; DX tro den chuoi thong bao "Score: "
    mov ah, 09h              ; Ham 09h cua ngat 21h: in chuoi ket thuc bang '$'
    int 21h                  ; Goi ngat DOS de in chuoi ra man hinh

    ; Chuyen diem cua nguoi choi sang chu so ASCII 
    xor ah, ah               ; Xoa thanh ghi AH (AL chua diem)
    mov al, [player_score]   ; Lay diem hien tai tu bien player_score
    mov dx, offset score1    ; DX tro den noi luu chuoi ket qua

    call CONVERT_TO_DECIMAL ; Goi ham chuyen AL sang dang chuoi ASCII luu vao DX

    ; In chuoi so diem vua chuyen 
    mov dx, offset score1    ; DX tro lai chuoi so vua tao
    mov ah, 09h              ; Ham 09h cua int 21h: in chuoi ket thuc bang '$'
    int 21h                  ; Goi ngat DOS de in chuoi diem

    ret                      ; Ket thuc ham
PRINT_PLAYER_SCORE endp

				
; Chuyen so nguyen thanh chuoi 3 chu so thap phan dang ASCII
CONVERT_TO_DECIMAL proc

    mov cx, 3              ; Lap 3 lan de lay 3 chu so (hang tram, chuc, don vi)
    lea si, score1 + 2     ; SI tro den vi tri cuoi cung cua chuoi score1 (hang don vi)

CONVERT_loop:
    mov dx, 0              ; Xoa DX de co the chia 16-bit (DX:AX) cho 10
    mov bx, 10             ; Dat so chia la 10
    div bx                 ; Chia AX (thuc te chi la AL vi DX = 0) cho 10
                           ; Thuong luu vao AL, phan du luu vao DL
    add dl, '0'            ; Chuyen so DL thanh ma ASCII (VD: 5 -> '5')
    mov [si], dl           ; Ghi ky tu ASCII vao vi tri hien tai trong chuoi
    dec si                 ; Lui ve 1 ky tu ve ben trai (tiep theo la hang chuc, hang tram)
    loop CONVERT_loop      ; Lap lai den khi CX = 0 (da ghi du 3 chu so)

    ret                    ; Ket thuc ham

CONVERT_TO_DECIMAL endp

; Khoi tao man hinh va hien thi diem
INIT_SCREEN proc near
    push ax            ; luu thanh ghi ax len stack de bao ton gia tri
    push cx            ; luu thanh ghi cx len stack de bao ton gia tri
    push si            ; luu thanh ghi si len stack de bao ton gia tri

    ; chuyen sang che do do hoa 13h (320x200, 256 mau)
    mov ah,00h         ; chuc nang chuyen doi che do hien thi
    mov al,13h         ; che do do hoa 13h
    int 10h            ; goi ngat BIOS de thay doi che do man hinh

    ; thiet lap doan nho man hinh
    mov ax, 0b800h     ; dia chi segment cho che do van ban (man hinh van ban)
    mov es, ax         ; gan segment es cho man hinh van ban

    ; xoa man hinh (chuyen sang che do van ban 3h tam thoi de xoa)
    mov ax, 03h        ; che do man hinh van ban chuan 80x25
    int 10h            ; goi ngat BIOS de doi che do

    ; goi thu tuc dien nen man hinh theo mau sac da dinh nghia
    call WRITE_SCREEN_BACKGROUND

    ; hien thi diem hien tai cua nguoi choi len man hinh
    call PRINT_PLAYER_SCORE

    ; ve thuc an dau tien tren man hinh
    mov si, [food_location] ; lay vi tri thuc an trong bo nho
    mov al, food_icon       ; ky tu bieu dien thuc an (icon)
    mov ah, food_color      ; mau sac thuc an
    mov es:[si], ax         ; ghi ky tu va mau len vi tri thuc an tren man hinh
    
    ; phuc hoi lai cac thanh ghi da luu truoc do
    pop si             ; phuc hoi thanh ghi si
    pop cx             ; phuc hoi thanh ghi cx
    pop ax             ; phuc hoi thanh ghi ax
    ret                ; tro ve vi tri goi ham
INIT_SCREEN endp 

; Ve toan bo giao dien man hinh game
WRITE_SCREEN_BACKGROUND proc near
    push si            ; luu thanh ghi SI de su dung lam con tro dia chi trong man hinh
    push ax            ; luu thanh ghi AX de su dung lam thanh ghi tam de ghi ky tu + mau
    push cx            ; luu thanh ghi CX de lam bien dem vong lap
    push bx            ; luu thanh ghi BX de phong tru, truoc khi su dung

    ; Ve header o dong 0 (dung de hien thi thong tin nhu ten game va diem)
    mov di, 0d              ; dat con tro dia chi man hinh o vi tri bat dau dong 0, cot 0
    mov cx, screen_width    ; Nap gia tri cua bien screen_width =80 vao thanh ghi CX, CX se duoc dung boi lenh REP.

DRAW_HEADER:                ; vong lap ve tung o tren dong 0
    mov al, 0h              ; ky tu trong (space) de xoa noi dung cu
    mov ah, 0Fh             ; mau chu trang tren nen den (0Fh hex)
    rep stosw               ; Lap lai (REP) lenh STOSW (Store String Word).
                            ; STOSW se ghi gia tri cua AX (gom ky tu trong AL va mau trong AH) 
                            ; vao vi tri bo nho ES:[DI], sau do tang DI len 2 (vi ghi mot WORD - 2 byte).
                            ; Lenh nay se lap lai CX lan, toan bo dong 0 se duoc to.

    ; Ve vien tren o dong 1, tu cot 0 den cot 79
    mov di, screen_width * 2d   ; dat con tro den dau dong 1 (dong 0 co 80 o * 2 byte moi o)
    mov cx, screen_width        ; so cot cung la 80

DRAW_TOP_BORDER:                ; vong lap ve vien tren
    mov al, 186                 ; ky tu vien doc (|) trong bo ky tu ASCII mo rong
    mov ah, border_color        ; mau vien la xanh duong (gia tri tu bien border_color)
    rep stosw                   ; tiep tuc den het 80 cot

    ; Ve vien duoi o dong cuoi man hinh (dong 24)
    mov di, (screen_hight-1) * screen_width * 2d   ; dia chi dong cuoi man hinh (dong 24)
    mov cx, screen_width                           ; so cot 80

DRAW_BOTTOM_BORDER:          ; vong lap ve vien duoi
    mov al, 186                 ; ky tu vien doc
    mov ah, border_color        ; mau vien xanh duong
    rep stosw

    ; Ve vien trai o cot 0, tu dong 2 den dong 23
    mov si, screen_width * 2d * 2    ; dat con tro den dong 2, cot 0 (bo qua dong 0 va dong 1)
    mov cx, screen_hight - 3          ; so dong de ve vien (22 dong, tu dong 2 den 23)

DRAW_LEFT_BORDER:             ; vong lap ve vien trai
    mov al, 186                 ; ky tu vien doc
    mov ah, border_color        ; mau vien xanh duong
    mov es:[si], ax             ; ghi vao man hinh tai vi tri SI
    add si, screen_width * 2d   ; nhay xuong dong tiep theo cung cot 0 (tang dia chi theo kich thuoc 1 dong)
    loop DRAW_LEFT_BORDER       ; lap lai het 22 dong

    ; Ve vien phai o cot 79, tu dong 2 den dong 23
    mov si, (screen_width - 1) * 2d + screen_width * 2d * 2   ; dia chi cot 79, dong 2
    mov cx, screen_hight - 3

DRAW_RIGHT_BORDER:            ; vong lap ve vien phai
    mov al, 186                 ; ky tu vien doc
    mov ah, border_color        ; mau vien xanh duong
    mov es:[si], ax
    add si, screen_width * 2d   ; nhay xuong dong tiep theo cung cot 79
    loop DRAW_RIGHT_BORDER

    ; Ve nen cho khu vuc choi (tu dong 2 den dong 23, cot 1 den cot 78)
    mov al, 0h                  ; ky tu khoang trong (space) de xoa noi dung cu
    mov ah, backgroud_color     ; mau nen vang
    mov di, (screen_width * 2d * 2) + 2d   ; vi tri dong 2, cot 1
    mov cx, 22d                 ; so dong nen trong khu vuc choi la 22 dong

DRAW_BACKGROUND_ROWS:          ; vong lap tung dong nen
    push cx                    ; luu lai so dong con lai tren stack
    mov cx, 78d                ; so cot nen trong khu vuc choi la 78 cot

DRAW_BACKGROUND_COLS:          ; vong lap tung cot nen trong dong
    rep stosw
    add di, 4d                 ; bo qua 2 byte cuoi dong (cot 79 va cot 80 khong ve nen)
    pop cx                     ; lay lai so dong con lai
    loop DRAW_BACKGROUND_ROWS  ; lap cho het 22 dong
    ; phuc hoi cac thanh ghi da luu truoc do
    pop bx
    pop cx
    pop ax
    pop si
    ret                        ;tro ve vi tri goi ham
WRITE_SCREEN_BACKGROUND endp

               
; Dat man hinh tro ve che do text binh thuong cua he dieu hanh
INIT_SCREEN_BACK_TO_OS proc near
    push ax                ; luu thanh ghi AX de tranh ghi de
    push cx                ; luu thanh ghi CX de tranh ghi de
    
    ; xoa man hinh hien tai (che do text 03h)
    mov ax, 03h            
    int 10h                ; goi interrupt de xoa man hinh va ve che do text co san
    
    ; chinh che do man hinh ve text binh thuong (mode 13h la do hoa, 03h la text)
    mov ah, 03h
    mov al, 13h
    int 10h                ; goi interrupt de chuyen ve che do do hoa (neu can)
    
    pop cx                 ; phuc hoi thanh ghi CX
    pop ax                 ; phuc hoi thanh ghi AX
    ret                    ; tro ve ham goi
INIT_SCREEN_BACK_TO_OS endp


				
; Khoi tao toa do ban dau cho than con ran va do dai ban dau
INIT_SNAKE_BODY proc near
    mov word ptr snake_body[6d], 4d + 3d * screen_width * 2d   ; Khoi tao toa do phan tu cuoi than ran
    mov word ptr snake_body[4d], 6d + 3d * screen_width * 2d   ; Khoi tao toa do phan tu thu 3 than ran
    mov word ptr snake_body[2d], 8d + 3d * screen_width * 2d   ; Khoi tao toa do phan tu thu 2 than ran
    mov word ptr snake_body[0d], 10d + 3d * screen_width * 2d  ; Khoi tao toa do dau ran
    mov word ptr [snake_len], 8d                                ; Dat do dai ran (so byte = 8)
    ret                                                         ; Ket thuc ham
INIT_SNAKE_BODY endp

; Ham cap nhat huong di chuyen cua ran tu phim nguoi dung, ESC de thoat game
GET_DIRECTION_BY_KEY proc near
    push ax                      ; Luu thanh ghi AX de giu gia tri hien tai
    push bx                      ; Luu thanh ghi BX de giu gia tri hien tai

    mov ah, 01h                  ; Ham 01h cua int16h: kiem tra phim co duoc bam khong (non-blocking)
    int 16h                      ; Goi interrupt ban phim, ket qua tra ve trong AH
    jz END_GET_DIRECTION_BY_KEY  ; Neu khong co phim duoc bam (Zero flag = 1), thoat ham

    cmp ah, END_GAME_KEY         ; So sanh phim vua bam voi phim thoat game (ESC)
    jz GET_DIRECTION_BY_KEY_EXIT_GAME_IS_ON  ; Neu bam ESC, chay nhan thoat game

    mov bh, ah                  ; Luu phim vua bam vao BH
    mov bl, [snake_direction]   ; Lay huong hien tai (con ran di chuyen) vao BL
    sub bh, bl                  ; Tinh hieu giua phim vua bam va huong hien tai

    cmp bh, 3d                  ; Neu hieu bang 3 (khoang cach hop le giua 2 huong)
    jz GET_DIRECTION_BY_KEY_VALID_MOVE ; Chap nhan di chuyen
    cmp bh, 5d                  ; Neu hieu bang 5 (khoang cach hop le)
    jz GET_DIRECTION_BY_KEY_VALID_MOVE

    neg bh                     ; Doi dau hieu cua hieu
    cmp bh, 3d                 ; Kiem tra lai hieu sau khi doi dau
    jz GET_DIRECTION_BY_KEY_VALID_MOVE
    cmp bh, 5d                 ; Kiem tra lai hieu sau khi doi dau
    jz GET_DIRECTION_BY_KEY_VALID_MOVE

    mov ah, 0Ch                ; Neu khong hop le (di nguoc lai ran), xoa bo dem phim
    int 21h
    jmp END_GET_DIRECTION_BY_KEY ; Thoat ham

GET_DIRECTION_BY_KEY_VALID_MOVE:
    mov [snake_direction], ah  ; Cap nhat huong di chuyen moi
    mov ah, 0Ch                ; Xoa bo dem phim sau khi cap nhat huong
    int 21h
    jmp END_GET_DIRECTION_BY_KEY

GET_DIRECTION_BY_KEY_EXIT_GAME_IS_ON:
    mov byte ptr [EXIT], 1h    ; Dat cot EXIT = 1, thong bao thoat game
    mov ah, 0Ch                ; Xoa bo dem phim
    int 21h

END_GET_DIRECTION_BY_KEY:
    pop bx                     ; Phuc hoi thanh ghi BX
    pop ax                     ; Phuc hoi thanh ghi AX
    ret                        ; Tra ve vi tri goi ham truoc do
GET_DIRECTION_BY_KEY endp


; Cap nhat vi tri moi cho dau ran truoc khi di chuyen
SHR_ARRAY proc near
    push bx                    ; Luu thanh ghi BX
    push ax                    ; Luu thanh ghi AX
    push si                    ; Luu thanh ghi SI

    mov si, [snake_len]        ; Lay do dai ran (so byte) vao SI
    sub si, 2h                 ; Tru 2 byte de bat dau tu phan tu cuoi cung truoc do
L1:
    mov ax, snake_body[si - 2h] ; Lay gia tri phan tu truoc do (vi tri i-1)
    mov snake_body[si], ax       ; Gan gia tri do vao vi tri hien tai (vi tri i)
    sub si, 2h                   ; Lui chi so ve phan tu tiep theo ben trai
    cmp si, 0h                   ; Kiem tra da den dau mang chua
    jnz L1                       ; Neu chua den dau mang, lap tiep

    pop si                      ; Phuc hoi thanh ghi SI
    pop ax                      ; Phuc hoi thanh ghi AX
    pop bx                      ; Phuc hoi thanh ghi BX
    ret                         ; Tra ve
SHR_ARRAY endp

main_menu proc
    mov di, 186h                 ; dat DI toi vi tri bat dau in chuoi dau tien tren man hinh (dia chi video)
    lea si, main1                ; dua con tro SI toi chuoi main1 (chuoi can in)
    mov cx, 10                  ; do dai chuoi "Snake Game" = 10 ky tu
lopem1:
    movsb                       ; copy 1 byte tu [DS:SI] sang [ES:DI], SI va DI tu tang 1
    inc di                      ; tang DI them 1 de den byte mau cua ky tu (moi ky tu 2 byte tren man hinh text)
    loop lopem1                 ; lap lai cho den khi CX = 0 (da copy xong chuoi)

    mov di, 33Eh                ; dat DI toi vi tri bat dau in chuoi thu 2 tren man hinh
    lea si, main2               ; con tro SI toi chuoi main2
    mov cx, 30                  ; do dai chuoi "WELCOME TO SNAKE GAME! enjoy:)" = 30 ky tu
lopem2:
    movsb                       ; copy 1 byte ky tu tu DS:SI sang ES:DI, SI va DI tang 1
    inc di                      ; tang DI them 1 den byte mau ky tu
    loop lopem2                 ; lap lai cho den khi CX = 0

    mov di, 3DEh                ; dat DI toi vi tri in chuoi thu 3
    lea si, main3               ; con tro SI toi main3
    mov cx, 36                  ; do dai chuoi "In this game you must eat 255 to win:" = 36 ky tu
lopem3:
    movsb                       ; copy 1 byte ky tu
    inc di                      ; tang DI 1 byte mau
    loop lopem3

    mov di, 47Eh                ; dat DI toi vi tri in chuoi thu 4
    lea si, main4               ; SI toi main4
    mov cx, 43                  ; do dai chuoi "Move the snake by pressing the keys >,<,,d" = 43 ky tu
lopem4:
    movsb                       ; copy 1 byte ky tu
    inc di                      ; tang DI byte mau
    loop lopem4

    mov di, 5DCh                ; vi tri in chuoi thu 5
    lea si, main5               ; SI toi main5
    mov cx, 9                   ; do dai chuoi "w:move up" = 9 ky tu
lopem5:
    movsb                       ; copy 1 byte ky tu
    inc di                      ; tang DI byte mau
    loop lopem5

    mov di, 67Ch                ; vi tri in chuoi thu 6
    lea si, main6               ; SI toi main6
    mov cx, 11                  ; do dai chuoi "s:move down" = 11 ky tu
lopem6:
    movsb                       ; copy 1 byte ky tu
    inc di                      ; tang DI byte mau
    loop lopem6

    mov di, 71Ch                ; vi tri in chuoi thu 7
    lea si, main7               ; SI toi main7
    mov cx, 12                  ; do dai chuoi "d:move right" = 12 ky tu
lopem7:
    movsb                       ; copy 1 byte ky tu
    inc di                      ; tang DI byte mau
    loop lopem7

    mov di, 7BCh                ; vi tri in chuoi thu 8
    lea si, main8               ; SI toi main8
    mov cx, 11                  ; do dai chuoi "a:move left" = 11 ky tu
lopem8:
    movsb                       ; copy 1 byte ky tu
    inc di                      ; tang DI byte mau
    loop lopem8

    mov di, 8DEh                ; vi tri in chuoi about1
    lea si, about1              ; SI toi about1
    mov cx, 28                  ; do dai chuoi "This game is done by: Team 6" = 28 ky tu
lopea1:
    movsb                       ; copy 1 byte ky tu
    inc di                      ; tang DI byte mau
    loop lopea1

    mov di, 97Eh                ; vi tri in about2
    lea si, about2              ; SI toi about2
    mov cx, 34                  ; do dai chuoi "To the computer architecture couse" = 34 ky tu
lopea2:
    movsb                       ; copy 1 byte ky tu
    inc di                      ; tang DI byte mau
    loop lopea2

    mov di, 0ABEh               ; vi tri in main9
    lea si, main9               ; SI toi main9
    mov cx, 35                  ; do dai chuoi "PRESS THE Esc KEY TO EXIT THE GAME." = 35 ky tu
lopem9:
    movsb                       ; copy 1 byte ky tu
    inc di                      ; tang DI byte mau
    loop lopem9

    mov di, 0B5Eh               ; vi tri in main10
    lea si, main10              ; SI toi main10
    mov cx, 25                  ; do dai chuoi "Press any key to start..." = 25 ky tu
lopem10:
    movsb                       ; copy 1 byte ky tu
    inc di                      ; tang DI byte mau
    loop lopem10

    mov ah, 7                   ; cho nguoi dung nhan phim ma khong hien ky tu len man hinh
    int 21h                     ; goi dich vu DOS nhan phim

    call clear                  ; xoa man hinh (goi ham clear)

    ret                         ; ket thuc ham main_menu
main_menu endp

clear proc
    push ax          ; luu gia tri thanh ghi ax
    push di          ; luu gia tri thanh ghi di
    push cx          ; luu gia tri thanh ghi cx
    push es          ; luu gia tri thanh ghi es

    ; thiet lap phan doan video (dia chi bo nho video o che do van ban: B800h)
    mov ax, 0B800h   ; gan dia chi phan doan video
    mov es, ax       ; chuyen vao thanh ghi es

    ; xoa tung vung da ghi trong main_menu bang cach ghi ky tu khoang trang (20h)
    ; mau mac dinh: trang tren nen den (07h)

    ; vung main1: 186h, do dai 11 ky tu
    mov di, 186h     ; dat chi so bat dau tai 186h
    mov cx, 10       ; so ky tu can xoa
    mov al, 20h      ; ky tu khoang trang
    mov ah, backgroud_color      ; thuoc tinh mau (trang tren nen den)
    rep stosw        ; ghi de khoang trang vao vung nay

    ; vung main2: 33Eh, do dai 48 ky tu
    mov di, 33Eh     ; dat chi so bat dau tai 33Eh
    mov cx, 30       ; so ky tu can xoa
    mov al, 20h      ; ky tu khoang trang
    mov ah, backgroud_color      ; thuoc tinh mau
    rep stosw        ; ghi de khoang trang vao vung nay

    ; vung main3: 3DEh, do dai 40 ky tu
    mov di, 3DEh     ; dat chi so bat dau tai 3DEh
    mov cx, 36       ; so ky tu can xoa
    mov al, 20h      ; ky tu khoang trang
    mov ah, backgroud_color      ; thuoc tinh mau
    rep stosw        ; ghi de khoang trang vao vung nay

    ; vung main4: 47Eh, do dai 43 ky tu
    mov di, 47Eh     ; dat chi so bat dau tai 47Eh
    mov cx, 43       ; so ky tu can xoa
    mov al, 20h      ; ky tu khoang trang
    mov ah, backgroud_color      ; thuoc tinh mau
    rep stosw        ; ghi de khoang trang vao vung nay

    ; vung main5: 5DCh, do dai 9 ky tu
    mov di, 5DCh     ; dat chi so bat dau tai 5DCh
    mov cx, 9        ; so ky tu can xoa
    mov al, 20h      ; ky tu khoang trang
    mov ah, backgroud_color      ; thuoc tinh mau
    rep stosw        ; ghi de khoang trang vao vung nay

    ; vung main6: 67Ch, do dai 11 ky tu
    mov di, 67Ch     ; dat chi so bat dau tai 67Ch
    mov cx, 11       ; so ky tu can xoa
    mov al, 20h      ; ky tu khoang trang
    mov ah, backgroud_color      ; thuoc tinh mau
    rep stosw        ; ghi de khoang trang vao vung nay

    ; vung main7: 71Ch, do dai 12 ky tu
    mov di, 71Ch     ; dat chi so bat dau tai 71Ch
    mov cx, 12       ; so ky tu can xoa
    mov al, 20h      ; ky tu khoang trang
    mov ah, backgroud_color      ; thuoc tinh mau
    rep stosw        ; ghi de khoang trang vao vung nay

    ; vung main8: 7BCh, do dai 11 ky tu
    mov di, 7BCh     ; dat chi so bat dau tai 7BCh
    mov cx, 11       ; so ky tu can xoa
    mov al, 20h      ; ky tu khoang trang
    mov ah,backgroud_color      ; thuoc tinh mau
    rep stosw        ; ghi de khoang trang vao vung nay

    ; vung about1: 8DEh, do dai 33 ky tu
    mov di, 8DEh     ; dat chi so bat dau tai 8DEh
    mov cx, 28       ; so ky tu can xoa
    mov al, 20h      ; ky tu khoang trang
    mov ah, backgroud_color      ; thuoc tinh mau
    rep stosw        ; ghi de khoang trang vao vung nay

    ; vung about2: 97Eh, do dai 37 ky tu
    mov di, 97Eh     ; dat chi so bat dau tai 97Eh
    mov cx, 34       ; so ky tu can xoa
    mov al, 20h      ; ky tu khoang trang
    mov ah, backgroud_color      ; thuoc tinh mau
    rep stosw        ; ghi de khoang trang vao vung nay

    ; vung main9: 0ABEh, do dai 53 ky tu
    mov di, 0ABEh    ; dat chi so bat dau tai 0ABEh
    mov cx, 35       ; so ky tu can xoa
    mov al, 20h      ; ky tu khoang trang
    mov ah, backgroud_color     ; thuoc tinh mau
    rep stosw        ; ghi de khoang trang vao vung nay

    ; vung main10: 0B5Eh, do dai 25 ky tu
    mov di, 0B5Eh    ; dat chi so bat dau tai 0B5Eh
    mov cx, 25       ; so ky tu can xoa
    mov al, 20h      ; ky tu khoang trang
    mov ah, backgroud_color      ; thuoc tinh mau
    rep stosw        ; ghi de khoang trang vao vung nay

    ; dat lai vi tri con tro neu can (tuy chon)
    mov ah, 02h      ; chuc nang dat vi tri con tro
    mov bh, 0        ; trang video 0
    mov dh, 0        ; dong 0
    mov dl, 0        ; cot 0
    int 10h          ; goi interrupt BIOS

    pop es           ; khoi phuc thanh ghi es
    pop cx           ; khoi phuc thanh ghi cx
    pop di           ; khoi phuc thanh ghi di
    pop ax           ; khoi phuc thanh ghi ax
    ret              ; tro ve tu thu tuc
clear endp

end MAIN
					