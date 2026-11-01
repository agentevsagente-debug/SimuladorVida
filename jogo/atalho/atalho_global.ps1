# Atalho global para a moldura, sem extensão do Godot.
#
# O Godot não tem API de atalho global. Este processo auxiliar registra o
# atalho no Windows (RegisterHotKey) e escreve "alternar" na saída padrão a
# cada vez que ele é apertado; a moldura lê essa saída por um pipe.
# Fecha sozinho quando o processo da moldura (-Pai) termina.
param([int]$Pai, [string]$Tecla = 'M')

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Threading;

public static class AtalhoGlobal {
    [StructLayout(LayoutKind.Sequential)]
    struct MSG { public IntPtr hwnd; public uint message; public IntPtr wParam, lParam; public uint time; public int x, y; }
    [DllImport("user32.dll")] static extern bool RegisterHotKey(IntPtr h, int id, uint mods, uint vk);
    [DllImport("user32.dll")] static extern int GetMessage(out MSG m, IntPtr h, uint min, uint max);
    [DllImport("user32.dll")] static extern bool PostThreadMessage(uint thread, uint msg, IntPtr w, IntPtr l);
    [DllImport("kernel32.dll")] static extern uint GetCurrentThreadId();

    const uint MOD_ALT = 0x1, MOD_CONTROL = 0x2, MOD_NOREPEAT = 0x4000;
    const uint WM_HOTKEY = 0x0312, WM_QUIT = 0x0012;

    public static void Rodar(int pai, char tecla) {
        if (!RegisterHotKey(IntPtr.Zero, 1, MOD_CONTROL | MOD_ALT | MOD_NOREPEAT, (uint)Char.ToUpper(tecla))) {
            Console.WriteLine("erro atalho_em_uso");
            return;
        }
        Console.WriteLine("pronto Ctrl+Alt+" + Char.ToUpper(tecla));
        uint thread = GetCurrentThreadId();
        var vigia = new Thread(() => {
            try { System.Diagnostics.Process.GetProcessById(pai).WaitForExit(); } catch { }
            PostThreadMessage(thread, WM_QUIT, IntPtr.Zero, IntPtr.Zero);
        });
        vigia.IsBackground = true;
        vigia.Start();
        MSG m;
        while (GetMessage(out m, IntPtr.Zero, 0, 0) > 0) {
            if (m.message == WM_HOTKEY) Console.WriteLine("alternar");
        }
    }
}
'@
[Console]::Out.Flush()
[AtalhoGlobal]::Rodar($Pai, $Tecla[0])
