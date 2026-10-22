from pathlib import Path
s=Path('tools/restore_commerce_terrain.py').read_text()
s=s.replace('evidence/commerce_2026-10-22','evidence/fairground_2026-10-22').replace("EVIDENCE / 'ClimbAndCollect.BeforeCommerce.rbxl'","ROOT / 'ClimbAndCollect.BeforeFairground.rbxl'").replace('ClimbAndCollect.FootholdExchange.Review.rbxl','ClimbAndCollect.Fairground.Review.rbxl')
Path('tools/restore_fairground_terrain.py').write_text(s)
