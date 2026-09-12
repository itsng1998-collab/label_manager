#ifndef RUNNER_DEBUG_PRINT_FILE_TARGET_H_
#define RUNNER_DEBUG_PRINT_FILE_TARGET_H_

#include <windows.h>
#include <filesystem>
#include <string>
#include <vector>

struct DebugPrintFileTarget {
  bool enabled = false;
  bool valid = true;
  std::filesystem::path path;

  bool AllowsRequest(bool file_only) const {
    return valid && (!file_only || enabled);
  }
};

inline DebugPrintFileTarget ValidateDebugPrintFileTarget(const std::wstring& value) {
  DebugPrintFileTarget result;
  if (value.empty()) return result;
  result.enabled = true;
  result.valid = false;
  try {
    result.path = value;
    result.valid = result.path.is_absolute() && result.path.extension() == L".prn" &&
        value.rfind(L"\\\\", 0) != 0 && !std::filesystem::exists(result.path) &&
        std::filesystem::is_directory(result.path.parent_path());
  } catch (const std::filesystem::filesystem_error&) {
    result.valid = false;
  }
  return result;
}

inline DebugPrintFileTarget ReadDebugPrintFileTarget() {
#ifdef _DEBUG
  constexpr wchar_t name[] = L"LABEL_MANAGER_DEBUG_PRINT_FILE";
  const DWORD required = GetEnvironmentVariableW(name, nullptr, 0);
  if (required == 0) return {};
  std::vector<wchar_t> value(required);
  const DWORD copied = GetEnvironmentVariableW(name, value.data(), required);
  if (copied == 0 || copied >= required) return {true, false, {}};
  return ValidateDebugPrintFileTarget(std::wstring(value.data(), copied));
#else
  return {};
#endif
}

#endif