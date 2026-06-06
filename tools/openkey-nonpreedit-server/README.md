# OpenKey NonPreedit Server

Server Go thử nghiệm để nhận transaction `PLAN` từ addon `nonPreedit` mode, tự bơm
`BackSpace` thật qua `/dev/uinput`, rồi phát lại `DONE` cho addon.

Addon hiện sẽ:

- tự tính `newWord` như cũ trong C++
- nếu có server ở socket `/tmp/openkey-nonpreedit.sock` thì giao phần
  `BACKSPACE + timer` sang server
- nếu không kết nối được server thì addon bỏ qua `nonPreedit` mode

## Chạy thử

```bash
cd tools/openkey-nonpreedit-server
go run . -socket /tmp/openkey-nonpreedit.sock
```

Nếu muốn đổi socket:

```bash
OPENKEY_NONPREEDIT_SERVER_SOCK=/tmp/openkey-nonpreedit.sock
```

Mặc định server im lặng. Bật log runtime khi cần debug:

```bash
OPENKEY_NONPREEDIT_SERVER_LOG=1
# hoặc
OPENKEY_NONPREEDIT_SERVER_DEBUG=1
```

## Protocol

Client -> server:

```text
PLAN <session> <tx> <backspaces> <inter_usec> <commit_delay_usec>
CANCEL <session>
```

Server -> client:

```text
DONE <session> <tx>
```
