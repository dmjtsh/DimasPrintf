#include <cstdlib>

extern "C" void DimasPrintf(const char* format_string, ...);

int main()
{
    char a = 'a';
    char b = 33;
    char c = 'c';
    char d = 'd';
    char e = 'e';
    int f = 34595;
    DimasPrintf("R%c%d %b pidr%c%% %c %c %c\n", a, f, f, b, c, d, e);

    system("pause");

    return 0;
}
