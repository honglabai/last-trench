#!/usr/bin/env python3
"""
최후의 참호 (LAST TRENCH) - Web 로컬 플레이 서버 실행기
"""
import http.server
import socketserver
import os
import sys
import webbrowser

PORT = 8080
WEB_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "builds", "web"))

if not os.path.isdir(WEB_DIR) or not os.path.isfile(os.path.join(WEB_DIR, "index.html")):
    print(f"[오류] Web 빌드 디렉터리를 찾을 수 없습니다: {WEB_DIR}")
    print("먼저 godot --export-release 'Web' builds/web/index.html 명령어로 빌드해 주세요.")
    sys.exit(1)

class CustomHTTPHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB_DIR, **kwargs)

    def end_headers(self):
        # Godot 4 WebGL / WASM 호환성 필수 헤더
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
        super().end_headers()

def main():
    port = PORT
    for p in range(PORT, PORT + 20):
        try:
            with socketserver.TCPServer(("127.0.0.1", p), CustomHTTPHandler) as httpd:
                url = f"http://127.0.0.1:{p}/"
                print("=" * 60)
                print("🎖️ [최후의 참호 (LAST TRENCH)] Web 플레이 서버 구동 완료!")
                print(f"👉 브라우저 주소: {url}")
                print("=" * 60)
                print("🎮 [PC 조작 가이드]")
                print("  - 화면 클릭: 마우스 시점 락 (360도 TPS 조준)")
                print("  - [W, A, S, D]: 참호 내부 병사 이동")
                print("  - [마우스 좌클릭]: 소총 발사")
                print("  - [마우스 우클릭]: ADS 견착 조준 (확대/정밀)")
                print("  - [R]: 탄약 재장전")
                print("  - [E]: 거점 좌/우 방어 슬롯 포탑 설치 및 수리")
                print("  - [ESC]: 마우스 커서 잠금 해제")
                print("=" * 60)
                print("서버를 종료하려면 Ctrl+C 를 누르세요.")
                
                # 자동으로 기본 브라우저 열기
                try:
                    webbrowser.open(url)
                except Exception:
                    pass
                
                try:
                    httpd.serve_forever()
                except KeyboardInterrupt:
                    print("\n서버가 종료되었습니다.")
                return
        except OSError:
            continue

if __name__ == "__main__":
    main()
