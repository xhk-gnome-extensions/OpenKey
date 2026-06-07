# OpenKey NonPreedit Server

Server Go để nhận transaction `PLAN` từ addon `NonPreedit` mode, tự bơm
`BackSpace` thật qua `/dev/uinput`, rồi phát lại `DONE` cho addon.

Addon hiện sẽ:

- tự tính `newWord` như cũ trong C++
- tự spawn server nếu socket `/tmp/openkey-nonpreedit.sock` chưa sẵn sàng
- giao phần `BACKSPACE + timer` sang server khi helper kết nối được
- fallback sang mode rewrite cũ nếu helper không sẵn sàng

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

Server tạo virtual keyboard qua `/dev/uinput` và đăng ký keycode chuẩn `1..255`
để tránh GNOME/Mutter thu hẹp global keymap khi thiết bị ảo được thêm vào.
Khi addon spawn server, server sẽ nhận `SIGTERM` lúc `fcitx5` tắt.

## Protocol

Client -> server:

```text
PLAN <session> <tx> <backspaces> <inter_usec> <commit_delay_usec>
```

Server -> client:

```text
DONE <session> <tx>
```
