/// Preencha com as credenciais do SEU projeto Supabase antes de testar o
/// upload na nuvem (Project Settings > API, no painel do Supabase).
///
/// Nenhuma dessas chaves é secreta o suficiente para não ir no app: a
/// "anon key" é pública por design (o Supabase usa Row Level Security para
/// proteger os dados). Ainda assim, evite commitar valores reais num
/// repositório público — considere ler de --dart-define em produção.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://hvsggibwgzjgglxlreuk.supabase.co';
  static const String publishableKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh2c2dnaWJ3Z3pqZ2dseGxyZXVrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAzNjg0MDMsImV4cCI6MjEwNTk0NDQwM30.GqNDlQlZsRyGH8MpZwuAfNarzsNOhoZDCRcX_wiPB78';

  /// Nome do bucket de Storage onde as imagens processadas são enviadas.
  /// Crie este bucket no painel do Supabase (Storage > New bucket) e marque
  /// como público, ou ajuste as políticas de RLS conforme necessário.
  static const String bucket = 'casseb';

  static bool get isConfigured => url.contains('supabase.co') && !url.contains('SEU-PROJETO');
}
