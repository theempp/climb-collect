-- World pill billboard (intel B4, homebase-intel A8): shared by WorldKit (server) and WorldPills (owner client price pills).
-- h 25, padX 9, r11, stroke 1.5, FredokaOne 12, MaxDistance 45, no AlwaysOnTop. Colours only from WorldStyle.
local S=require(script.Parent.WorldStyle)
local function rgb(c) if type(c)=='string' then c=assert(S.color[c],c) end;return Color3.fromRGB(c[1],c[2],c[3]) end -- WorldStyle rgb helper
return function(adornee,text,stroke,offset)
 local b=Instance.new('BillboardGui');b.Name='Pill';b.Size=UDim2.fromOffset(160,25) -- 160 = legacy container width (A8), REC
 b.StudsOffset=offset or Vector3.new(0,3,0);b.MaxDistance=S.sign.maxDistance;b.AlwaysOnTop=false;b.LightInfluence=0;b.Adornee=adornee
 local f=Instance.new('Frame');f.Size=UDim2.fromScale(1,1);f.BackgroundColor3=rgb('signNight');f.BackgroundTransparency=S.signT;f.Parent=b
 local c=Instance.new('UICorner');c.CornerRadius=UDim.new(0,S.sign.radius);c.Parent=f
 local s=Instance.new('UIStroke');s.Thickness=S.sign.stroke;s.Color=rgb(stroke or 'signStroke');s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;s.Parent=f
 local pd=Instance.new('UIPadding');pd.PaddingLeft=UDim.new(0,9);pd.PaddingRight=UDim.new(0,9);pd.Parent=f
 local t=Instance.new('TextLabel');t.Name='Label';t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Text=text or ''
 t.TextColor3=rgb('signText');t.TextSize=S.sign.textSize;t.Font=Enum.Font[S.fonts.body];t.TextTruncate=Enum.TextTruncate.AtEnd;t.Parent=f
 -- TODO(atlas): A8 text outline (1 px `outline` T.2) has no world-style A/B row; 7th instance left out.
 b.Parent=adornee;return b
end
