package com.abilitylink.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "ability_link_alerts",
                "Ability Link alerts",
                NotificationManager.IMPORTANCE_HIGH,
            )
            channel.description =
                "Bookings, reminders, messages and nearby alerts"
            getSystemService(NotificationManager::class.java)
                .createNotificationChannel(channel)
        }
    }
}
