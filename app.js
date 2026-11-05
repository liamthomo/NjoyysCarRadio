const form = document.getElementById('radio-form');
const urlInput = document.getElementById('youtube-url');
const status = document.getElementById('status');
const volumeInput = document.getElementById('volume');

let player;
let playerReady = false;
let pendingPlayback;

function post(name, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data)
    });
}

function extractVideoId(value) {
    let url;
    try {
        url = new URL(value);
    } catch {
        return null;
    }

    const host = url.hostname.toLowerCase().replace(/^www\./, '');
    let id = null;
    if (host === 'youtu.be') {
        id = url.pathname.split('/').filter(Boolean)[0];
    } else if (['youtube.com', 'm.youtube.com', 'music.youtube.com'].includes(host)) {
        if (url.pathname === '/watch') {
            id = url.searchParams.get('v');
        } else {
            const match = url.pathname.match(/^\/(?:embed|shorts|live)\/([^/?]+)/);
            id = match && match[1];
        }
    }

    return id && /^[\w-]{11}$/.test(id) ? id : null;
}

function setVolume(value) {
    if (player && typeof player.setVolume === 'function') {
        player.setVolume(Math.round(Math.max(0, Math.min(1, value)) * 100));
    }
}

function play(data) {
    pendingPlayback = data;
    if (!playerReady) {
        return;
    }

    player.loadVideoById({
        videoId: data.videoId,
        startSeconds: data.offset || 0
    });
    setVolume(data.volume);
    player.unMute();
}

function onYouTubeIframeAPIReady() {
    player = new YT.Player('player', {
        width: '200',
        height: '200',
        playerVars: {
            autoplay: 1,
            controls: 0,
            disablekb: 1,
            playsinline: 1,
            rel: 0,
            enablejsapi: 1,
            origin: window.location.origin
        },
        events: {
            onReady: () => {
                playerReady = true;
                if (pendingPlayback) {
                    play(pendingPlayback);
                }
            },
            onError: (event) => {
                const messages = {
                    2: 'YouTube rejected that video ID.',
                    5: 'This video cannot be played in the embedded player.',
                    100: 'Video not found or unavailable.',
                    101: 'The video owner does not allow embedded playback.',
                    150: 'The video owner does not allow embedded playback.'
                };
                status.textContent = messages[event.data] || 'YouTube could not play this video.';
            }
        }
    });
}

window.onYouTubeIframeAPIReady = onYouTubeIframeAPIReady;
const apiScript = document.createElement('script');
apiScript.src = 'https://www.youtube.com/iframe_api';
document.head.appendChild(apiScript);

form.addEventListener('submit', (event) => {
    event.preventDefault();
    const videoId = extractVideoId(urlInput.value.trim());
    if (!videoId) {
        status.textContent = 'Enter a valid YouTube video link.';
        return;
    }

    status.textContent = 'Requesting playback...';
    post('play', { videoId });
});

document.getElementById('stop').addEventListener('click', () => post('stop'));
document.getElementById('close').addEventListener('click', () => post('close'));

volumeInput.addEventListener('input', () => {
    post('setUserVolume', { volume: Number(volumeInput.value) / 100 });
});

window.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        post('close');
    }
});

window.addEventListener('message', ({ data }) => {
    if (data.type === 'open') {
        document.body.classList.add('visible');
        status.textContent = 'Only the driver can change the station. Nearby players can hear it.';
    } else if (data.type === 'close') {
        document.body.classList.remove('visible');
    } else if (data.type === 'requestResult') {
        status.textContent = data.message;
    } else if (data.type === 'play') {
        play(data);
    } else if (data.type === 'stop') {
        pendingPlayback = null;
        if (player && typeof player.stopVideo === 'function') {
            player.stopVideo();
        }
    } else if (data.type === 'volume' || data.type === 'localVolume') {
        setVolume(data.volume);
    }
});
