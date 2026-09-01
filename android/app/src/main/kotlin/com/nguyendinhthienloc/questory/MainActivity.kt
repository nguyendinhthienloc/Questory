//package com.nguyendinhthienloc.questory
//
//import android.content.BroadcastReceiver
//import android.content.Context
//import android.content.Intent
//import android.content.IntentFilter
//import android.os.Build
//import io.flutter.embedding.android.FlutterActivity
//import io.flutter.embedding.engine.FlutterEngine
//import io.flutter.plugin.common.EventChannel
//import io.flutter.plugin.common.MethodChannel
//
//Tai Test
//class MainActivity: FlutterActivity() {
//    // Định nghĩa tên kênh giao tiếp (phải khớp chính xác với chuỗi bên Dart)
//    private val COMMAND_CHANNEL = "com.questory.tracking/command"
//    private val EVENT_CHANNEL = "com.questory.tracking/event"
//
//    private var locationReceiver: BroadcastReceiver? = null
//
//    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//        super.configureFlutterEngine(flutterEngine)
//
//        // 1. METHOD CHANNEL: Lắng nghe lệnh điều khiển từ Flutter (Start/Stop)
//        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, COMMAND_CHANNEL).setMethodCallHandler { call, result ->
//            when (call.method) {
//                "startService" -> {
//                    val serviceIntent = Intent(this, TrackingService::class.java)
//                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//                        startForegroundService(serviceIntent)
//                    } else {
//                        startService(serviceIntent)
//                    }
//                    result.success("Foreground Service Started")
//                }
//                "stopService" -> {
//                    val serviceIntent = Intent(this, TrackingService::class.java)
//                    stopService(serviceIntent)
//                    result.success("Foreground Service Stopped")
//                }
//                else -> result.notImplemented()
//            }
//        }
//
//        // 2. EVENT CHANNEL: Lắng nghe Broadcast từ TrackingService và đẩy lên Flutter liên tục
//        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
//            object : EventChannel.StreamHandler {
//                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
//                    locationReceiver = object : BroadcastReceiver() {
//                        override fun onReceive(context: Context?, intent: Intent?) {
//                            if (intent?.action == "LocationUpdates") {
//                                val lat = intent.getDoubleExtra("lat", 0.0)
//                                val lng = intent.getDoubleExtra("lng", 0.0)
//                                val distance = intent.getDoubleExtra("distance", 0.0)
//
//                                // Đóng gói thành HashMap để Flutter dễ parse thành Map<String, dynamic>
//                                val data = mapOf(
//                                    "lat" to lat,
//                                    "lng" to lng,
//                                    "distance" to distance
//                                )
//                                events?.success(data)
//                            }
//                        }
//                    }
//                    // Đăng ký nhận tín hiệu
//                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
//                        registerReceiver(locationReceiver, IntentFilter("LocationUpdates"), Context.RECEIVER_NOT_EXPORTED)
//                    } else {
//                        registerReceiver(locationReceiver, IntentFilter("LocationUpdates"))
//                    }
//                }
//
//                override fun onCancel(arguments: Any?) {
//                    locationReceiver?.let { unregisterReceiver(it) }
//                    locationReceiver = null
//                }
//            }
//        )
//    }
//}