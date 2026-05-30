abstract class CryptoService {
  Future<void> generateKeyPair();
  Future<List<int>> sign(List<int> message);
  Future<String> getPublicKeyPem();
  Future<bool> hasKeyPair();
}
