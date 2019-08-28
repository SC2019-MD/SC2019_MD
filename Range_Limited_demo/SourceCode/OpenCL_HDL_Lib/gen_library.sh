rm *.aoc*
rm -rf RL_LJ_Evaluation
aocl library hdl-comp-pkg RL_LJ_Evaluation.xml -o RL_LJ_Evaluation.aoco
aocl library create -name RL_LJ_Evaluation RL_LJ_Evaluation.aoco