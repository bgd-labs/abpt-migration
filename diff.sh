cast etherscan-source --chain 1 -d etherscan/StkABPTBefore 0x9921c8cea5815364d0f8350e6cbe9042a92448c9
cast etherscan-source --chain 1 -d etherscan/StkGHO 0x50F9d4E28309303F0cdcAc8AF0b569e8b75Ab857

cast etherscan-source --chain 1 -d etherscan/StkABPTNoCooldown 0x1401bf602d95a0d52978961644B7BDD117Cf6Df6
cast etherscan-source --chain 1 -d etherscan/StkAAVEWSTETH 0x4ad4a620EEaE490d5872F69845104fAeFB67EFc4

make git-diff before=etherscan/StkABPTBefore after=etherscan/StkABPTNoCooldown out=STKABPT
make git-diff before=etherscan/StkGHO after=etherscan/StkAAVEWSTETH out=STKAAVEWSTETH
