final RegExp _dbConnectionProbePattern = RegExp(
  r'^SELECT\s+1\s*;?$',
  caseSensitive: false,
);

bool isDbConnectionProbeSql(String sql) {
  return _dbConnectionProbePattern.hasMatch(sql.trim());
}