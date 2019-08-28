#include <fstream>

int Gen_Pos_Cache_Num_Selection(std::string* common_path);
void gen_14_cell_num(int x0, int y0, int z0, std::ofstream &fout);
void gen_14_cell_readout_addr(int x0, int y0, int z0, std::ofstream &fout);
int pbc_find_band_num(int x, int y, int z);
int pbc_sub_one(int a, int boundary);
int pbc_add_one(int a, int boundary);
