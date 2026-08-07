using System;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;

internal static class Program
{
    private const char AsianFontSlot = '1';
    private const string KoreanDownloadName = "Korean";
    private const string PackageFileName = "AZ_KO16x16.DAT";

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern bool SetDllDirectory(string pathName);

    [STAThread]
    private static int Main(string[] args)
    {
        if (args.Length != 2)
        {
            Console.Error.WriteLine("usage: godex_font_helper <GoLabel directory> <output directory>");
            return 2;
        }

        string goLabelDirectory = Path.GetFullPath(args[0]);
        string outputDirectory = Path.GetFullPath(args[1]);
        string fontFile = Path.Combine(goLabelDirectory, "FontFile.dll");
        string dialogAssemblyPath = Path.Combine(goLabelDirectory, "QlabelDlg.DLL");
        if (!File.Exists(fontFile) || !File.Exists(dialogAssemblyPath))
        {
            Console.Error.WriteLine("GoLabel font components not found: " + goLabelDirectory);
            return 3;
        }

        Directory.CreateDirectory(outputDirectory);
        string packagePath = Path.Combine(outputDirectory, PackageFileName);
        if (File.Exists(packagePath))
        {
            File.Delete(packagePath);
        }

        string goLabelDataDirectory = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
            "Godex");
        string koreanCodeTable = Path.Combine(goLabelDataDirectory, "Table", "KSC.bin");
        if (!File.Exists(koreanCodeTable))
        {
            Console.Error.WriteLine("GoLabel Korean code table not found: " + koreanCodeTable);
            return 4;
        }
        if (!SetDllDirectory(goLabelDirectory))
        {
            Console.Error.WriteLine("Cannot configure GoLabel DLL directory");
            return 4;
        }
        Directory.SetCurrentDirectory(goLabelDataDirectory);
        AppDomain.CurrentDomain.AssemblyResolve += delegate(object sender, ResolveEventArgs eventArgs)
        {
            string assemblyName = new AssemblyName(eventArgs.Name).Name + ".dll";
            string dependencyPath = Path.Combine(goLabelDirectory, assemblyName);
            return File.Exists(dependencyPath) ? Assembly.LoadFrom(dependencyPath) : null;
        };

        object dialog = null;
        try
        {
            Assembly dialogAssembly = Assembly.LoadFrom(dialogAssemblyPath);
            Type dialogType = dialogAssembly.GetType("QlabelDlg.DownloadAsianFont", true);
            dialog = Activator.CreateInstance(dialogType);
            dialogType.GetField("workDir").SetValue(dialog, outputDirectory);
            dialogType.GetField("charIndex").SetValue(dialog, AsianFontSlot);
            MethodInfo createKoreanFont = dialogType.GetMethod(
                "StartDownloadAsianFontKO",
                BindingFlags.Instance | BindingFlags.NonPublic);
            bool succeeded = (bool)createKoreanFont.Invoke(
                dialog,
                new object[] { 0, KoreanDownloadName });
            if (!succeeded || !File.Exists(packagePath))
            {
                Console.Error.WriteLine("GoLabel Korean font generation failed");
                return 5;
            }
        }
        catch (Exception error)
        {
            Console.Error.WriteLine(error.GetBaseException().Message);
            return 4;
        }
        finally
        {
            IDisposable disposable = dialog as IDisposable;
            if (disposable != null)
            {
                disposable.Dispose();
            }
        }

        var package = new FileInfo(packagePath);
        if (package.Length == 0)
        {
            Console.Error.WriteLine("CreateKOFontFile produced an empty package");
            return 6;
        }

        Console.WriteLine(package.FullName);
        Console.WriteLine(package.Length);
        return 0;
    }
}