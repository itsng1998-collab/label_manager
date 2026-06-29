package com.example.fortune_sheet

import android.util.Xml
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.FileInputStream
import org.xmlpull.v1.XmlPullParser

class FortuneSheetPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "fortune_sheet/fonts")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (call.method == "listFontFamilies") {
            result.success(installedFontFamilies())
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun installedFontFamilies(): List<String> {
        val families = linkedSetOf(
            "sans-serif",
            "serif",
            "monospace",
            "casual",
            "cursive",
            "sans-serif-condensed",
            "sans-serif-medium",
            "sans-serif-light",
            "sans-serif-black",
            "sans-serif-smallcaps",
            "serif-monospace"
        )
        val fontConfig = File("/system/etc/fonts.xml")
        if (!fontConfig.exists()) {
            return families.toList()
        }
        FileInputStream(fontConfig).use { input ->
            val parser = Xml.newPullParser()
            parser.setInput(input, null)
            var eventType = parser.eventType
            while (eventType != XmlPullParser.END_DOCUMENT) {
                if (eventType == XmlPullParser.START_TAG &&
                    (parser.name == "family" || parser.name == "alias")
                ) {
                    parser.getAttributeValue(null, "name")
                        ?.trim()
                        ?.takeIf { it.isNotEmpty() }
                        ?.let { families.add(it) }
                }
                eventType = parser.next()
            }
        }
        return families.toList()
    }
}
