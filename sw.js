// GPX Tracker service worker (최소 구성)
// 데이터는 모두 서버(Supabase)에 있고 지도 타일도 인터넷이 필요하므로, 앱 화면 자체를 캐시하지 않는다.
// 그래서 항상 최신 index.html이 열린다. (설치 가능한 웹 앱 조건을 채우기 위한 파일)
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', e => e.waitUntil(self.clients.claim()));
self.addEventListener('fetch', () => { /* 기본 네트워크 동작 그대로 */ });
