# P-Key

P-Key là một chương trình nhỏ dùng để **gõ chữ Việt có dấu trên máy vi tính sử dụng hệ điều hành Windows**.

Chương trình được viết bằng **Free Pascal** và **Lazarus**, có thể thường trú tại khay hệ thống và cho phép sử dụng hai lối gõ chữ Việt thông dụng là **VNI** và **Telex**.

## Đặc điểm của chương trình

- Có hai lối gõ chữ Việt: **VNI** và **Telex**
- Cho ra chữ Việt theo mã **Unicode**
- Nhận phím trực tiếp từ bàn phím thông qua cơ chế móc bàn phím của Windows
- Có thể thu nhỏ và thường trú tại khay hệ thống
- Không cho chạy nhiều bản chương trình cùng một lúc
- Chương trình được đóng thành một tập tin thi hành duy nhất, thuận tiện cho việc sao chép và sử dụng

## Điều kiện sử dụng

Muốn biên dịch chương trình, máy cần có:

- Hệ điều hành **Windows**
- Bộ **Lazarus**
- Trình biên dịch **Free Pascal**

Theo mặc định, Lazarus được đặt tại thư mục:

```text
C:\lazarus
```

Nếu Lazarus được cài ở một thư mục khác, cần khai báo biến môi trường `LAZARUS_DIR` trước khi tiến hành biên dịch.

## Biên dịch chương trình

Tại dấu nhắc lệnh, thi hành:

```bat
build.bat
```

Sau khi biên dịch thành công, chương trình sẽ tạo ra tập tin:

```text
src\p_key.exe
```

Khi đem chương trình sang máy khác, chỉ cần sao chép tập tin `p_key.exe`.

Chương trình sử dụng các thư viện chuẩn có sẵn của Windows, vì vậy không cần chép thêm các tập tin DLL riêng.

## Cách sử dụng

Muốn chạy chương trình, thi hành:

```bat
src\p_key.exe
```

Sau khi chương trình khởi động, người sử dụng chọn một trong hai lối gõ:

- **VNI**
- **Telex**

Khi đóng cửa sổ chính, chương trình không chấm dứt mà sẽ được thu nhỏ xuống khay hệ thống.

Muốn chấm dứt chương trình hoàn toàn, chọn mục **Thoat**.

## Lối gõ VNI

Trong lối gõ VNI, các phím số được dùng để đặt dấu và tạo chữ Việt.

| Phím | Công dụng |
| --- | --- |
| `1` | dấu sắc |
| `2` | dấu huyền |
| `3` | dấu hỏi |
| `4` | dấu ngã |
| `5` | dấu nặng |
| `6` | tạo dấu mũ |
| `7` | tạo dấu móc |
| `8` | tạo dấu trăng |
| `9` | tạo chữ đ |
| `0` | bỏ dấu thanh |

Thí dụ:

```text
tie61ng
```

sẽ cho kết quả:

```text
tiếng
```

## Lối gõ Telex

Trong lối gõ Telex, các chữ cái được dùng để đặt dấu và tạo chữ Việt.

| Phím | Công dụng |
| --- | --- |
| `s` | dấu sắc |
| `f` | dấu huyền |
| `r` | dấu hỏi |
| `x` | dấu ngã |
| `j` | dấu nặng |
| `aa` | â |
| `aw` | ă |
| `ee` | ê |
| `oo` | ô |
| `ow` | ơ |
| `uw` | ư |
| `dd` | đ |
| `z` | bỏ dấu chữ Việt |

Thí dụ:

```text
tieengs
```

sẽ cho kết quả:

```text
tiếng
```

## Kiểm tra chương trình

Để biên dịch chương trình kiểm tra, dùng lệnh:

```bat
fpc -Fu=src -Fu=tests -FcUTF8 tests\test_vni_engine.pas
```

Sau đó chạy:

```bat
tests\test_vni_engine.exe
```

Chương trình kiểm tra dùng để thử các quy tắc biến đổi chữ Việt của cả hai lối gõ VNI và Telex.

## Sơ đồ các tập tin

```text
src/
  app.ico
      Hình biểu tượng của chương trình

  app.rc
      Tài nguyên biểu tượng dùng cho Windows

  main_form.pas
      Phần giao diện chính của chương trình và phần nhận phím từ Windows

  p_key.lpr
      Chương trình chính, dùng để khởi động P-Key

  p_key.lpi
      Tập tin đề án của Lazarus

  syllable_parser.pas
      Phần phân tích tiếng Việt và xác định vị trí đặt dấu

  vietnamese_chars.pas
      Bảng các chữ cái Việt theo mã Unicode

  vni_engine.pas
      Bộ xử lý việc biến đổi chữ gõ theo lối VNI và Telex

tests/
  test_vni_engine.pas
      Chương trình dùng để kiểm tra bộ xử lý gõ chữ Việt
```

## Ghi chú

P-Key được thiết kế theo lối đơn giản, gọn nhẹ, không cần cài đặt phức tạp.

Người sử dụng chỉ cần có tập tin `p_key.exe` là có thể chạy chương trình trên máy Windows thích hợp.