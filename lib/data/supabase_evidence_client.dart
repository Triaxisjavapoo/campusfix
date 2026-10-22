import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../domain/models.dart';
import 'campusfix_exception.dart';
import 'evidence_config.dart';

/// The Edge Function verifies Firebase identity and current Firestore access.
/// Administrative Supabase keys are never sent to the browser.
class SupabaseEvidenceClient {
  SupabaseEvidenceClient(this.auth);
  final FirebaseAuth auth;

  Uri _endpoint(Map<String, String> parameters) {
    final base = Uri.tryParse(EvidenceConfig.supabaseUrl);
    if (base == null || base.scheme != 'https' || base.host.isEmpty) {
      throw const CampusFixException(
        'El servicio de fotografías necesita configuración. Contacta al administrador.',
      );
    }
    return base.replace(
      path: '/functions/v1/incident-evidence',
      queryParameters: parameters,
    );
  }

  Future<http.Response> _send(
    String method,
    Uri url, {
    Uint8List? bytes,
    String? contentType,
  }) async {
    final user = auth.currentUser;
    if (user == null) {
      throw const CampusFixException('Inicia sesión para continuar.');
    }
    try {
      // Retry only authentication failures; never repeat a possibly saved upload.
      for (var attempt = 0; attempt < 2; attempt++) {
        final token = await user.getIdToken(attempt == 1);
        if (auth.currentUser?.uid != user.uid || token == null) {
          throw const CampusFixException(
            'La sesión cambió. Vuelve a ingresar.',
          );
        }
        final headers = {
          'Authorization': 'Bearer $token',
          'Content-Type': ?contentType,
        };
        final response = await (switch (method) {
          'POST' => http.post(url, headers: headers, body: bytes),
          'DELETE' => http.delete(url, headers: headers),
          _ => http.get(url, headers: headers),
        }).timeout(const Duration(seconds: 90));
        if (response.statusCode == 401 && attempt == 0) continue;
        if (auth.currentUser?.uid != user.uid) {
          throw const CampusFixException(
            'La sesión cambió. Vuelve a ingresar.',
          );
        }
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }
        throw CampusFixException(switch (response.statusCode) {
          409 =>
            method == 'DELETE'
                ? 'El reporte cambió. Revisa sus datos antes de eliminarlo.'
                : 'Este reporte está en proceso de eliminación.',
          400 || 415 => 'Adjunta una imagen JPEG, PNG o WebP válida.',
          401 => 'Tu sesión venció. Vuelve a iniciar sesión.',
          403 =>
            method == 'DELETE'
                ? 'Solo un administrador activo puede eliminar reportes.'
                : 'No tienes permiso para acceder a las fotos de este reporte.',
          404 => 'La fotografía o el reporte ya no están disponibles.',
          413 => 'Cada imagen debe pesar como máximo 5 MB.',
          429 || 507 => 'Se alcanzó el límite de fotografías del servicio.',
          _ =>
            method == 'DELETE'
                ? 'No se completó la eliminación. Reabre el reporte y selecciona Reintentar eliminación.'
                : 'No se pudo completar la operación con la fotografía. Inténtalo de nuevo.',
        });
      }
    } on TimeoutException {
      throw CampusFixException(
        method == 'DELETE'
            ? 'La eliminación tardó demasiado. Revisa el listado y reintenta si el reporte sigue pendiente.'
            : 'La conexión tardó demasiado. Revisa el reporte antes de volver a adjuntar la foto.',
      );
    } on http.ClientException {
      throw CampusFixException(
        method == 'DELETE'
            ? 'No se pudo conectar. Revisa el estado del reporte antes de reintentar la eliminación.'
            : 'No se pudo conectar con las fotografías. Revisa tu conexión.',
      );
    }
    throw const CampusFixException('No se pudo validar la sesión.');
  }

  Future<void> deleteIncident(Incident incident) async {
    final response = await _send(
      'DELETE',
      _endpoint({'incidentId': incident.id, 'version': '${incident.version}'}),
    );
    final data = jsonDecode(response.body);
    if (data is! Map || data['deleted'] != true) {
      throw const CampusFixException(
        'Revisa el listado para confirmar la eliminación.',
      );
    }
  }

  Future<void> upload({
    required String incidentId,
    required String name,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final response = await _send(
      'POST',
      _endpoint({'incidentId': incidentId, 'name': name}),
      bytes: bytes,
      contentType: contentType,
    );
    final data = jsonDecode(response.body);
    if (data is! Map || data['evidenceId'] is! String) {
      throw const CampusFixException(
        'Revisa el reporte para confirmar si la fotografía se guardó.',
      );
    }
  }

  Future<Uint8List> download(IncidentEvidence evidence) async {
    final parts = evidence.path.split('/');
    if (parts.length != 4 ||
        parts[0] != 'incidents' ||
        parts[3] != evidence.id) {
      throw const CampusFixException(
        'La referencia de la fotografía no es válida.',
      );
    }
    final response = await _send(
      'GET',
      _endpoint({'incidentId': parts[1], 'evidenceId': evidence.id}),
    );
    return response.bodyBytes;
  }
}
