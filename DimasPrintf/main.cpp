#include <cstdlib>

extern "C" void DimasPrintf(const char* format_string, ...);

int main()
{
    char a = 'a';
    char b = 33;
    char c = 'c';
    char d = 'd';
    char e = 'e';
    DimasPrintf("R%c pidr%c%% %c %c %c\n", a, b, c, d, e);

    system("pause");

    return 0;
}
