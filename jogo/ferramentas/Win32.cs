// Chamadas do Windows usadas pelos scripts de verificação e medição.
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class Win32 {
    [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }

    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] public static extern IntPtr WindowFromPoint(POINT p);
    [DllImport("user32.dll")] public static extern IntPtr GetAncestor(IntPtr h, uint flags);
    [DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr h, int index);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern bool GetCursorPos(out POINT p);
    [DllImport("user32.dll")] public static extern void mouse_event(uint flags, int dx, int dy, uint data, IntPtr extra);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, System.Text.StringBuilder s, int max);

    public static IntPtr RaizEm(int x, int y) {
        POINT p; p.X = x; p.Y = y;
        return GetAncestor(WindowFromPoint(p), 2); // GA_ROOT
    }

    public static string Titulo(IntPtr h) {
        var s = new System.Text.StringBuilder(256);
        GetWindowText(h, s, 256);
        return s.ToString();
    }

    public static void Clicar(int x, int y) {
        POINT antes; GetCursorPos(out antes);
        SetCursorPos(x, y);
        System.Threading.Thread.Sleep(60);
        mouse_event(0x0002, 0, 0, 0, IntPtr.Zero); // botão esquerdo para baixo
        mouse_event(0x0004, 0, 0, 0, IntPtr.Zero); // para cima
        System.Threading.Thread.Sleep(60);
        SetCursorPos(antes.X, antes.Y);
    }

    public static void Arrastar(int x, int y, int dx, int dy) {
        POINT antes; GetCursorPos(out antes);
        SetCursorPos(x, y);
        System.Threading.Thread.Sleep(60);
        mouse_event(0x0002, 0, 0, 0, IntPtr.Zero);
        for (int i = 1; i <= 10; i++) {
            System.Threading.Thread.Sleep(30);
            SetCursorPos(x + dx * i / 10, y + dy * i / 10);
        }
        System.Threading.Thread.Sleep(60);
        mouse_event(0x0004, 0, 0, 0, IntPtr.Zero);
        System.Threading.Thread.Sleep(60);
        SetCursorPos(antes.X, antes.Y);
    }

    public static Bitmap Capturar(int x, int y, int w, int h) {
        var bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        using (var g = Graphics.FromImage(bmp)) g.CopyFromScreen(x, y, 0, 0, new Size(w, h));
        return bmp;
    }

    static int[] Pixels(Bitmap bmp) {
        var d = bmp.LockBits(new Rectangle(0, 0, bmp.Width, bmp.Height), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        var px = new int[bmp.Width * bmp.Height];
        Marshal.Copy(d.Scan0, px, 0, px.Length);
        bmp.UnlockBits(d);
        return px;
    }

    // Fração dos blocos k × k (alinhados à origem da região) que têm uma cor só.
    // Com escala inteira e filtro "nearest", deve ser 1.0.
    public static double BlocosUniformes(Bitmap bmp, int x0, int y0, int w, int h, int k) {
        var px = Pixels(bmp);
        int total = 0, bons = 0;
        for (int by = y0; by + k <= y0 + h; by += k)
            for (int bx = x0; bx + k <= x0 + w; bx += k) {
                int c = px[by * bmp.Width + bx];
                bool ok = true;
                for (int y = by; y < by + k && ok; y++)
                    for (int x = bx; x < bx + k; x++)
                        if (px[y * bmp.Width + x] != c) { ok = false; break; }
                total++; if (ok) bons++;
            }
        return total == 0 ? 0 : (double)bons / total;
    }

    // Fração dos pixels da região iguais nas duas capturas.
    public static double Iguais(Bitmap a, Bitmap b, int x0, int y0, int w, int h) {
        var pa = Pixels(a); var pb = Pixels(b);
        int total = 0, iguais = 0;
        for (int y = y0; y < y0 + h; y++)
            for (int x = x0; x < x0 + w; x++) {
                total++; if (pa[y * a.Width + x] == pb[y * b.Width + x]) iguais++;
            }
        return (double)iguais / total;
    }
}
