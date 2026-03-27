import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:cv_tech/core/config/network_config.dart';
import 'package:cv_tech/data/api/api_client.dart';

/// Service Socket.IO singleton pour la communication en temps réel
class SocketService {
  static SocketService? _instance;
  io.Socket? _socket;
  bool _isConnected = false;
  bool _disabledForSession = false;
  final Set<String> _pendingPostRooms = <String>{};

  // Stream controllers pour les événements
  final _commentController = StreamController<Map<String, dynamic>>.broadcast();
  final _notificationController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _messagesReadController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionRequestController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageDeletedController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageUpdatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _conversationDeletedController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onNewComment => _commentController.stream;
  Stream<Map<String, dynamic>> get onNotification => _notificationController.stream;
  Stream<Map<String, dynamic>> get onNewMessage => _messageController.stream;
  Stream<Map<String, dynamic>> get onUserTyping => _typingController.stream;
  Stream<Map<String, dynamic>> get onMessagesRead => _messagesReadController.stream;
  Stream<Map<String, dynamic>> get onConnectionRequest => _connectionRequestController.stream;
  Stream<Map<String, dynamic>> get onMessageDeleted => _messageDeletedController.stream;
  Stream<Map<String, dynamic>> get onMessageUpdated => _messageUpdatedController.stream;
  Stream<Map<String, dynamic>> get onConversationDeleted => _conversationDeletedController.stream;
  bool get isConnected => _isConnected;

  SocketService._internal();

  bool _shouldDisableHostedSocket(dynamic error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('404') ||
        msg.contains('not upgraded') ||
        msg.contains('websocketexception');
  }

  static SocketService get instance {
    _instance ??= SocketService._internal();
    return _instance!;
  }

  /// Initialiser la connexion Socket.IO
  Future<void> connect() async {
    if (_disabledForSession) return;
    if (_isConnected && _socket != null) return;

    try {
      final token = await ApiClient().getAccessToken();
      if (token == null) {
        if (kDebugMode) print('🔌 [Socket] No token, cannot connect');
        return;
      }

      // Construire l'URL socket (port séparé du backend API)
      final backendUrl = await NetworkConfig.getBackendUrl();
      final uri = Uri.parse(backendUrl);
      const configuredSocketPort = NetworkConfig.defaultSocketPort;
      final isLocalHost = uri.host == 'localhost' ||
          uri.host == '127.0.0.1' ||
          uri.host == '10.0.2.2';
      final isUnsafeWebLocalhost = kIsWeb &&
          configuredSocketPort == '6000' &&
          isLocalHost;

      final socketPort = isUnsafeWebLocalhost ? '6001' : configuredSocketPort;
        final normalizedPort = uri.port > 0
          ? ':${uri.port}'
          : (uri.scheme == 'https' ? ':443' : ':80');
      final socketUrl = isLocalHost
          ? '${uri.scheme}://${uri.host}:$socketPort'
          : '${uri.scheme}://${uri.host}$normalizedPort';

      if (isUnsafeWebLocalhost && kDebugMode) {
        print('⚠️ [Socket] localhost:6000 is unsafe on web, using 6001');
      }

      if (kDebugMode) print('🔌 [Socket] Connecting to $socketUrl');

      _socket = io.io(socketUrl, <String, dynamic>{
        'transports': ['websocket', 'polling'],
        'autoConnect': false,
        'path': '/socket.io/',
        'auth': {'token': token},
        'reconnection': isLocalHost,
        'reconnectionAttempts': isLocalHost ? 10 : 0,
        'reconnectionDelay': 1000,
        'reconnectionDelayMax': 5000,
      });

      _socket!.onConnect((_) {
        _isConnected = true;
        if (kDebugMode) print('✅ [Socket] Connected');

        // Flush queued post-room joins requested before connection was ready.
        if (_pendingPostRooms.isNotEmpty) {
          for (final postId in _pendingPostRooms.toList()) {
            _socket?.emit('join_post', {'postId': postId});
            if (kDebugMode) print('📌 [Socket] Joined queued post room: $postId');
          }
          _pendingPostRooms.clear();
        }
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        if (kDebugMode) print('❌ [Socket] Disconnected');
      });

      _socket!.onError((error) {
        if (kDebugMode) print('❌ [Socket] Error: $error');
        if (!isLocalHost && _shouldDisableHostedSocket(error)) {
          _disabledForSession = true;
          disconnect();
          if (kDebugMode) {
            print('⚠️ [Socket] Disabled for this session: hosted endpoint unavailable');
          }
        }
      });

      _socket!.onConnectError((error) {
        if (kDebugMode) print('❌ [Socket] Connect error: $error');
        if (!isLocalHost && _shouldDisableHostedSocket(error)) {
          _disabledForSession = true;
          disconnect();
          if (kDebugMode) {
            print('⚠️ [Socket] Disabled for this session: hosted endpoint unavailable');
          }
        }
      });

      // Écouter les événements de commentaires
      _socket!.on('new_comment', (data) {
        if (kDebugMode) print('💬 [Socket] New comment received');
        if (data is Map<String, dynamic>) {
          _commentController.add(data);
        } else if (data is Map) {
          _commentController.add(Map<String, dynamic>.from(data));
        }
      });

      // Écouter les notifications
      _socket!.on('notification', (data) {
        if (kDebugMode) print('🔔 [Socket] Notification received');
        if (data is Map<String, dynamic>) {
          _notificationController.add(data);
        } else if (data is Map) {
          _notificationController.add(Map<String, dynamic>.from(data));
        }
      });

      // Écouter les nouveaux messages de chat
      _socket!.on('new_message', (data) {
        if (kDebugMode) print('💬 [Socket] New message received');
        if (data is Map<String, dynamic>) {
          _messageController.add(data);
        } else if (data is Map) {
          _messageController.add(Map<String, dynamic>.from(data));
        }
      });

      // Écouter les indicateurs de frappe
      _socket!.on('user_typing', (data) {
        if (data is Map<String, dynamic>) {
          _typingController.add(data);
        } else if (data is Map) {
          _typingController.add(Map<String, dynamic>.from(data));
        }
      });

      // Écouter les accusés de lecture
      _socket!.on('messages_read', (data) {
        if (data is Map<String, dynamic>) {
          _messagesReadController.add(data);
        } else if (data is Map) {
          _messagesReadController.add(Map<String, dynamic>.from(data));
        }
      });

      // Écouter les événements de connexion (demandes, acceptations, rejets)
      _socket!.on('connection_request', (data) {
        if (kDebugMode) print('🤝 [Socket] Connection request event received');
        if (data is Map<String, dynamic>) {
          _connectionRequestController.add(data);
        } else if (data is Map) {
          _connectionRequestController.add(Map<String, dynamic>.from(data));
        }
      });

      // Écouter les suppressions de messages
      _socket!.on('message_deleted', (data) {
        if (kDebugMode) print('🗑️ [Socket] Message deleted event received');
        if (data is Map<String, dynamic>) {
          _messageDeletedController.add(data);
        } else if (data is Map) {
          _messageDeletedController.add(Map<String, dynamic>.from(data));
        }
      });

      // Écouter les modifications de messages
      _socket!.on('message_updated', (data) {
        if (kDebugMode) print('✏️ [Socket] Message updated event received');
        if (data is Map<String, dynamic>) {
          _messageUpdatedController.add(data);
        } else if (data is Map) {
          _messageUpdatedController.add(Map<String, dynamic>.from(data));
        }
      });

      // Écouter les suppressions de conversations
      _socket!.on('conversation_deleted', (data) {
        if (kDebugMode) print('🗑️ [Socket] Conversation deleted event received');
        if (data is Map<String, dynamic>) {
          _conversationDeletedController.add(data);
        } else if (data is Map) {
          _conversationDeletedController.add(Map<String, dynamic>.from(data));
        }
      });

      _socket!.connect();
    } catch (e) {
      if (kDebugMode) print('❌ [Socket] Connection error: $e');
    }
  }

  /// Rejoindre la room d'un post pour recevoir les commentaires en temps réel
  void joinPostRoom(String postId) {
    if (_socket == null || !_isConnected) {
      _pendingPostRooms.add(postId);
      if (kDebugMode) {
        print('⚠️ [Socket] join_post queued (not connected yet): $postId');
      }
      // Ensure a connection attempt is running.
      connect();
      return;
    }
    _socket?.emit('join_post', {'postId': postId});
    if (kDebugMode) print('📌 [Socket] Joined post room: $postId');
  }

  /// Quitter la room d'un post
  void leavePostRoom(String postId) {
    _pendingPostRooms.remove(postId);
    if (_socket == null || !_isConnected) {
      return;
    }
    _socket?.emit('leave_post', {'postId': postId});
    if (kDebugMode) print('📌 [Socket] Left post room: $postId');
  }

  /// Émettre l'indicateur "est en train d'écrire"
  void emitTyping({required String conversationId, required bool isTyping}) {
    _socket?.emit('typing', {
      'conversationId': conversationId,
      'isTyping': isTyping,
    });
  }

  /// Signaler qu'on a vu la conversation
  void emitViewConversation(String otherUserId) {
    _socket?.emit('view_conversation', {'conversationId': otherUserId});
  }

  /// Déconnecter le socket
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  /// Nettoyer les ressources
  void dispose() {
    disconnect();
    _commentController.close();
    _notificationController.close();
    _messageController.close();
    _typingController.close();
    _messagesReadController.close();
    _connectionRequestController.close();
    _messageDeletedController.close();
    _messageUpdatedController.close();
    _conversationDeletedController.close();
    _instance = null;
  }
}
