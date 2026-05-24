let ws = null;
let connected = false;

function connect() {
  const ip = document.getElementById('serverIP').value;
  const port = document.getElementById('serverPort').value;
  const username = document.getElementById('username').value;

  const url = `ws://${ip}:${port}`;

  ws = new WebSocket(url);

  ws.onopen = () => {
    connected = true;
    document.getElementById('connect-panel').style.display = 'none';
    document.getElementById('game-ui').style.display = 'flex';

    ws.send(JSON.stringify({
      type: 'Hello',
      data: { clientVersion: '1.0.0', protocolVersion: 1 }
    }));

    ws.send(JSON.stringify({
      type: 'Auth',
      data: { username, password: '' }
    }));
  };

  ws.onmessage = (event) => {
    try {
      const packet = JSON.parse(event.data);
      handlePacket(packet);
    } catch (e) {
      console.error('Parse error:', e);
    }
  };

  ws.onclose = () => {
    connected = false;
    document.getElementById('connect-panel').style.display = 'block';
    document.getElementById('game-ui').style.display = 'none';
    addChatMessage('System', 'Disconnected from server');
  };
}

function disconnect() {
  if (ws) {
    ws.close();
    ws = null;
  }
}

function sendChat() {
  const input = document.getElementById('chatInput');
  if (!input.value.trim()) return;

  if (ws && connected) {
    ws.send(JSON.stringify({
      type: 'ChatMessage',
      data: { message: input.value }
    }));
  }
  input.value = '';
}

function handlePacket(packet) {
  switch (packet.type) {
    case 'HelloResponse':
      console.log('Server:', packet.data.serverVersion);
      break;

    case 'AuthResponse':
      if (packet.data.success) {
        addChatMessage('System', 'Connected to server');
      } else {
        addChatMessage('System', 'Auth failed: ' + packet.data.reason);
      }
      break;

    case 'ChatMessage':
      addChatMessage(packet.data.sender, packet.data.message);
      break;

    case 'PlayerJoin':
      addChatMessage('System', packet.data.name + ' joined the server');
      updatePlayerList();
      break;

    case 'PlayerLeave':
      addChatMessage('System', packet.data.name + ' left the server');
      updatePlayerList();
      break;

    case 'PlayerList':
      // handled by other extensions
      break;

    case 'Kick':
      addChatMessage('System', 'Kicked: ' + packet.data.reason);
      disconnect();
      break;
  }
}

function addChatMessage(sender, message) {
  const container = document.getElementById('chat-messages');
  const msgDiv = document.createElement('div');
  msgDiv.className = 'chat-msg';

  if (sender === 'System') {
    msgDiv.innerHTML = '<span style="color:#ff9800">[' + sender + ']</span> ' + escapeHtml(message);
  } else {
    msgDiv.innerHTML = '<span class="chat-sender">' + escapeHtml(sender) + ':</span> ' + escapeHtml(message);
  }

  container.appendChild(msgDiv);
  container.scrollTop = container.scrollHeight;

  if (container.children.length > 100) {
    container.removeChild(container.firstChild);
  }
}

function updatePlayerList() {
  // Placeholder: updates player list in UI
}

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}
