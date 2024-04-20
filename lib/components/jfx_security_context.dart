import 'dart:io';
import 'package:dio/io.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/io_client.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';

class JfxSecurityContext {
  IOHttpClientAdapter? httpAdapter;
  CacheManager? cacheManager;

  JfxSecurityContext() {
    SecurityContext securityContext = SecurityContext();
    bool useCustomTls = true; // We will check the configuration here.
    if (useCustomTls) {
      rootBundle.load("assets/certificates/chain.pem").then((certBytes) {
        rootBundle.load("assets/certificates/key.pem").then((keyBytes) {
          rootBundle.load("assets/certificates/ca.pem").then((caBytes) {
            securityContext
                .setTrustedCertificatesBytes(caBytes.buffer.asUint8List());
            securityContext.usePrivateKeyBytes(keyBytes.buffer.asUint8List());
            securityContext
                .useCertificateChainBytes(certBytes.buffer.asUint8List());
          });
        });
      });
    }

    httpAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        HttpClient client = HttpClient(context: securityContext);
        return client;
      },
    );

    // Initialize CacheManager with fully initialized SecurityContext
    cacheManager = CacheManager(
      Config(
        'jellyflix',
        fileService: HttpFileService(
          httpClient: IOClient(HttpClient(context: securityContext)),
        ),
      ),
    );
  }

  // Public function accepting an Object parameter
  void configurePlayer(Player player) async {
    if (player.platform is NativePlayer) {
      Directory? appSupportDir = await getTemporaryDirectory();
      String appSupportPath = appSupportDir.path;
      await (player.platform as dynamic)
          .setProperty('tls-ca-file', '$appSupportPath/ca.pem');
      await (player.platform as dynamic)
          .setProperty('tls-cert-file', '$appSupportPath/chain.pem');
      await (player.platform as dynamic)
          .setProperty('tls-key-file', '$appSupportPath/key.pem');
      await (player.platform as dynamic).setProperty('tls-verify', 'yes');
      await (player.platform as dynamic).setProperty('network-timeout', '30');
      // Todo network timeout should be a global static across all http libs
    }
  }
}
