package com.nguyendinhthienloc.questory

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.location.Location
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority

class TrackingService : Service() {
    private var fusedLocationClient: FusedLocationProviderClient? = null
    private var locationCallback: LocationCallback? = null

    private var lastLocation: Location? = null
    private var totalDistanceMeters = 0.0

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Questory")
            .setContentText("Đang ghi nhận lộ trình chạy bộ...")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setOngoing(true)
            .build()

        startForeground(NOTIFICATION_ID, notification)
        startLocationUpdates()

        return START_STICKY
    }

    @SuppressLint("MissingPermission")
    private fun startLocationUpdates() {
        val locationRequest = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 2000)
            .setMinUpdateDistanceMeters(2.0f)
            .build()

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                for (location in locationResult.locations) {
                    processNewLocation(location)
                }
            }
        }

        fusedLocationClient?.requestLocationUpdates(locationRequest, locationCallback!!, mainLooper)
        Log.d(TAG, "Đã bắt đầu thu thập GPS")
    }

    private fun processNewLocation(newLocation: Location) {
        if (lastLocation != null) {
            val distance = lastLocation!!.distanceTo(newLocation)
            val timeDeltaSeconds = (newLocation.time - lastLocation!!.time) / 1000

            if (timeDeltaSeconds > 0) {
                val speed = distance / timeDeltaSeconds
                if (speed > MAX_VALID_SPEED_MPS) {
                    Log.w(TAG, "Lọc nhiễu: Bỏ qua điểm nhảy GPS phi lý (Vận tốc: $speed m/s)")
                    return
                }
            }
            totalDistanceMeters += distance.toDouble()
        }

        lastLocation = newLocation

        Log.d(TAG, "Tọa độ: ${newLocation.latitude}, ${newLocation.longitude} | Tổng quãng đường: $totalDistanceMeters m")

        val broadcastIntent = Intent("LocationUpdates").apply {
            putExtra("lat", newLocation.latitude)
            putExtra("lng", newLocation.longitude)
            putExtra("distance", totalDistanceMeters)
        }
        sendBroadcast(broadcastIntent)
    }

    override fun onDestroy() {
        super.onDestroy()
        if (fusedLocationClient != null && locationCallback != null) {
            fusedLocationClient?.removeLocationUpdates(locationCallback!!)
            Log.d(TAG, "Đã dừng thu thập GPS")
        }
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Questory Tracking",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(serviceChannel)
        }
    }

    companion object {
        private const val CHANNEL_ID = "TrackingChannel"
        private const val NOTIFICATION_ID = 1
        private const val TAG = "TrackingService"
        private const val MAX_VALID_SPEED_MPS = 11.0
    }
}