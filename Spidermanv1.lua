local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UserInputService=game:GetService("UserInputService")
local TweenService=game:GetService("TweenService")
local Workspace=game:GetService("Workspace")
local Debris=game:GetService("Debris")

local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")

if _G.RidKidHubShutdown then pcall(_G.RidKidHubShutdown) end
if _G.PremiumHubShutdown then pcall(_G.PremiumHubShutdown) end
for _,n in ipairs({"RidKidHub","PremiumHub","SpiderControlsGui","SpiderSystemGui","AnimationHub"}) do
	local o=playerGui:FindFirstChild(n)
	if o then o:Destroy() end
end
pcall(function() RunService:UnbindFromRenderStep("AnimHubMotion") end)
pcall(function() RunService:UnbindFromRenderStep("SpiderPose") end)

local Bus={}
local Tracked={}
local function track(c)
	Tracked[#Tracked+1]=c
	return c
end
local function baseOf(m)
	local b=m:GetAttribute("SpiderBase")
	if typeof(b)~="CFrame" then
		b=m.C0
		m:SetAttribute("SpiderBase",b)
	end
	return b
end

do
local H=Enum.HumanoidStateType
local rad,sin,cos,abs,max,min,clamp,exp,pi=math.rad,math.sin,math.cos,math.abs,math.max,math.min,math.clamp,math.exp,math.pi
local V=Vector3.new
local ZERO=V(0,0,0)
local KEYS={"root","waist","neck","rs","re","ls","le","rh","rk","lh","lk"}

local function lerp(a,b,t) return a+(b-a)*t end
local function ease(t) t=clamp(t,0,1) return t*t*(3-2*t) end
local function mix(a,b,w)
	local r={}
	for _,k in ipairs(KEYS) do
		r[k]=(a[k] or ZERO):Lerp(b[k] or ZERO,w)
	end
	return r
end

local function climbPose(c)
	local s=sin(c.cl)
	return {
		waist=V(-4,0,0),
		rs=V(150+s*28,0,10),re=V(18,0,0),
		ls=V(150-s*28,0,-10),le=V(18,0,0),
		rh=V(35-s*30,0,4),rk=V(-(30+max(0,-s)*35),0,0),
		lh=V(35+s*30,0,-4),lk=V(-(30+max(0,s)*35),0,0),
	}
end

local function sitPose(c)
	local b=sin(c.t*1.4)
	return {
		waist=V(-2+b*0.8,0,0),neck=V(4,c.look.X*0.5,0),
		rs=V(28,0,10),re=V(55,0,0),ls=V(28,0,-10),le=V(55,0,0),
		rh=V(90,0,4),rk=V(-90,0,0),lh=V(90,0,-4),lk=V(-90,0,0),
	}
end

local function idle1(c)
	local t,l=c.t,c.look
	local br,sw=sin(t*1.7),sin(t*0.65)
	return {
		root=V(0,l.X*0.12,sw*1.6),
		waist=V(-10+br*1.2,l.X*0.28,-sw*1.2),
		neck=V(10+l.Y,l.X*0.7,sw),
		rs=V(10+br*2,0,13+br),re=V(38+br*3,0,0),
		ls=V(8-br*2,0,-13-br),le=V(42-br*3,0,0),
		rh=V(30,0,4+sw),rk=V(-58,0,0),
		lh=V(38,0,-4),lk=V(-70,0,0),
	}
end

local function move1(c)
	local p,rb=c.phase,c.rb
	local s,co=sin(p),cos(p)
	local stride=lerp(26,56,rb)
	local kn=lerp(40,95,rb)
	local sw=lerp(16,36,rb)
	local lean=lerp(8,30,rb)*c.dirLean
	local tr=c.turn
	return {
		root=V(-lean*0.3,s*7*rb,tr),
		waist=V(-lean*0.7,-s*9*rb,-tr*0.6),
		neck=V(lean*0.85,s*8*rb,0),
		rs=V(-28*rb-s*sw,0,12+8*rb),re=V(40+max(0,-s)*30*rb,0,0),
		ls=V(-28*rb+s*sw,0,-12-8*rb),le=V(40+max(0,s)*30*rb,0,0),
		rh=V(s*stride,0,3),rk=V(-(10+max(0,co)*kn),0,0),
		lh=V(-s*stride,0,-3),lk=V(-(10+max(0,-co)*kn),0,0),
	}
end

local function fall1(c)
	local f,t=c.fall,c.t
	local fl=sin(t*10)*3*f
	return {
		waist=V(-8,0,0),neck=V(10,0,0),
		rs=V(20+f*30+fl,0,58+f*28),re=V(12,0,0),
		ls=V(20+f*30-fl,0,-58-f*28),le=V(12,0,0),
		rh=V(16,0,9+f*12),rk=V(-38,0,0),
		lh=V(-12,0,-9-f*12),lk=V(-60,0,0),
	}
end

local function land1(c)
	local d=c.depth
	return {
		waist=V(-(28+18*d),0,0),neck=V(24+14*d,0,0),
		rs=V(lerp(30,72,d),0,lerp(42,14,d)),re=V(lerp(50,8,d),0,0),
		ls=V(lerp(30,-45,d),0,lerp(-42,-64,d)),le=V(lerp(50,30,d),0,0),
		rh=V(lerp(58,88,d),0,6),rk=V(-lerp(98,105,d),0,0),
		lh=V(lerp(58,-20,d),0,-8),lk=V(-lerp(98,125,d),0,0),
	}
end

local function swim1(c)
	local sb=clamp(c.speed/6,0,1)
	local lean=lerp(22,68,sb)
	local sp=c.t*(4.6+3*sb)
	local a,b=sin(sp),sin(sp+pi)
	local k=sin(sp*2.4)
	return {
		root=V(-lean,0,0),
		waist=V(0,a*9,0),neck=V(lean*0.85,-a*8,0),
		rs=V(108+a*76,0,8),re=V(28+cos(sp)*22,0,0),
		ls=V(108+b*76,0,-8),le=V(28+cos(sp+pi)*22,0,0),
		rh=V(k*14,0,2),rk=V(-14-max(0,k)*14,0,0),
		lh=V(-k*14,0,-2),lk=V(-14-max(0,-k)*14,0,0),
	}
end

local jumps1={
	{flip=ZERO,pose=function(p)
		local u=ease(p*3)
		return {
			waist=V(-12*u,0,0),neck=V(12*u,0,0),
			rs=V(150*u,0,26*u),re=V(20*u,0,0),
			ls=V(150*u,0,-26*u),le=V(20*u,0,0),
			rh=V(70*u,0,6*u),rk=V(-110*u,0,0),
			lh=V(55*u,0,-6*u),lk=V(-95*u,0,0),
		}
	end},
	{flip=ZERO,pose=function(p)
		local u=ease(p*3)
		return {
			waist=V(-38*u,0,0),neck=V(34*u,0,0),
			rs=V(172*u,0,8*u),re=V(6*u,0,0),
			ls=V(172*u,0,-8*u),le=V(6*u,0,0),
			rh=V(-28*u,0,3*u),rk=V(-44*u,0,0),
			lh=V(-12*u,0,-3*u),lk=V(-26*u,0,0),
		}
	end},
	{flip=V(-360,0,0),pose=function(p)
		local u=ease(p*3)
		return {
			waist=V(-18*u,0,0),
			rs=V(70*u,0,12*u),re=V(95*u,0,0),
			ls=V(70*u,0,-12*u),le=V(95*u,0,0),
			rh=V(82*u,0,4*u),rk=V(-118*u,0,0),
			lh=V(82*u,0,-4*u),lk=V(-118*u,0,0),
		}
	end},
	{flip=ZERO,pose=function(p)
		local u=ease(p*3)
		return {
			waist=V(-6*u,0,0),neck=V(8*u,0,0),
			rs=V(30*u,0,105*u),re=V(10*u,0,0),
			ls=V(30*u,0,-105*u),le=V(10*u,0,0),
			rh=V(15*u,0,28*u),rk=V(-22*u,0,0),
			lh=V(15*u,0,-28*u),lk=V(-22*u,0,0),
		}
	end},
	{flip=V(0,360,0),pose=function(p)
		local u=ease(p*3)
		return {
			waist=V(-8*u,0,0),
			rs=V(12*u,0,22*u),re=V(105*u,0,0),
			ls=V(12*u,0,-22*u),le=V(105*u,0,0),
			rh=V(22*u,0,2*u),rk=V(-52*u,0,0),
			lh=V(12*u,0,-2*u),lk=V(-42*u,0,0),
		}
	end},
}

local function idle2(c)
	local t,l=c.t,c.look
	local br,sw=sin(t*1.5),sin(t*0.5)
	return {
		root=V(0,l.X*0.1,sw*1.2),
		waist=V(-2+br*1.2,l.X*0.3,-sw*0.8),
		neck=V(2+l.Y,l.X*0.7,0),
		rs=V(4+br*1.6,0,7),re=V(16,0,0),
		ls=V(6-br*1.6,0,-7),le=V(18,0,0),
		rh=V(3,0,3+sw*0.8),rk=V(-6,0,0),
		lh=V(-2,0,-3),lk=V(-4,0,0),
	}
end

local function move2(c)
	local p,rb=c.phase,c.rb
	local s,co=sin(p),cos(p)
	local stride=lerp(32,68,rb)
	local kn=lerp(45,105,rb)
	local sw=lerp(26,62,rb)
	local lean=lerp(4,17,rb)*c.dirLean
	local tr=c.turn
	return {
		root=V(-lean*0.3,s*5*rb,tr),
		waist=V(-lean*0.7,-s*12*rb,-tr*0.6),
		neck=V(lean*0.6,s*10*rb,0),
		rs=V(-s*sw,0,6),re=V(lerp(18,88,rb),0,0),
		ls=V(s*sw,0,-6),le=V(lerp(18,88,rb),0,0),
		rh=V(s*stride,0,2),rk=V(-(6+max(0,co)*kn),0,0),
		lh=V(-s*stride,0,-2),lk=V(-(6+max(0,-co)*kn),0,0),
	}
end

local function fall2(c)
	local f,t=c.fall,c.t
	local s=sin(t*7)
	return {
		waist=V(-4,0,0),neck=V(6,0,0),
		rs=V(150+f*20,0,18),re=V(10,0,0),
		ls=V(150+f*20,0,-18),le=V(10,0,0),
		rh=V(35+s*20,0,3),rk=V(-60-max(0,s)*20,0,0),
		lh=V(35-s*20,0,-3),lk=V(-60-max(0,-s)*20,0,0),
	}
end

local function land2(c)
	local d=c.depth
	return {
		waist=V(-(22+16*d),0,0),neck=V(20+12*d,0,0),
		rs=V(lerp(55,80,d),0,lerp(18,24,d)),re=V(lerp(40,18,d),0,0),
		ls=V(lerp(55,80,d),0,lerp(-18,-24,d)),le=V(lerp(40,18,d),0,0),
		rh=V(lerp(48,70,d),0,5),rk=V(-lerp(90,110,d),0,0),
		lh=V(lerp(40,62,d),0,-5),lk=V(-lerp(84,104,d),0,0),
	}
end

local function swim2(c)
	local sb=clamp(c.speed/6,0,1)
	local lean=lerp(18,60,sb)
	local sp=c.t*(3.6+2.4*sb)
	local a=sin(sp)
	local o=max(0,cos(sp))
	local k=sin(sp*2)
	return {
		root=V(-lean,0,0),
		waist=V(a*5,0,0),neck=V(lean*0.8+a*6,0,0),
		rs=V(105+a*65,0,14+o*34),re=V(24+o*30,0,0),
		ls=V(105+a*65,0,-14-o*34),le=V(24+o*30,0,0),
		rh=V(12+k*16,0,5),rk=V(-24-max(0,k)*20,0,0),
		lh=V(12+k*16,0,-5),lk=V(-24-max(0,k)*20,0,0),
	}
end

local jumps2={
	{flip=ZERO,pose=function(p)
		local u=ease(p*3)
		return {
			waist=V(-25*u,0,0),neck=V(10*u,0,0),
			rs=V(90*u,0,20*u),re=V(8*u,0,0),
			ls=V(90*u,0,-20*u),le=V(8*u,0,0),
			rh=V(85*u,0,4*u),rk=V(-6*u,0,0),
			lh=V(85*u,0,-4*u),lk=V(-6*u,0,0),
		}
	end},
	{flip=V(360,0,0),pose=function(p)
		local u=ease(p*3)
		return {
			waist=V(6*u,0,0),
			rs=V(160*u,0,14*u),re=V(14*u,0,0),
			ls=V(160*u,0,-14*u),le=V(14*u,0,0),
			rh=V(78*u,0,3*u),rk=V(-120*u,0,0),
			lh=V(78*u,0,-3*u),lk=V(-120*u,0,0),
		}
	end},
	{flip=ZERO,pose=function(p)
		local u=ease(p*3)
		return {
			waist=V(-10*u,0,0),neck=V(8*u,0,0),
			rs=V(-35*u,0,20*u),re=V(40*u,0,0),
			ls=V(110*u,0,-15*u),le=V(30*u,0,0),
			rh=V(75*u,0,2*u),rk=V(-35*u,0,0),
			lh=V(-45*u,0,-2*u),lk=V(-95*u,0,0),
		}
	end},
	{flip=V(0,0,-360),pose=function(p)
		local u=ease(p*3)
		return {
			waist=V(-6*u,0,0),
			rs=V(60*u,0,16*u),re=V(90*u,0,0),
			ls=V(60*u,0,-16*u),le=V(90*u,0,0),
			rh=V(70*u,0,4*u),rk=V(-100*u,0,0),
			lh=V(70*u,0,-4*u),lk=V(-100*u,0,0),
		}
	end},
	{flip=V(0,-360,0),pose=function(p)
		local u=ease(p*3)
		return {
			waist=V(-4*u,0,0),neck=V(6*u,0,0),
			rs=V(10*u,0,72*u),re=V(14*u,0,0),
			ls=V(10*u,0,-72*u),le=V(14*u,0,0),
			rh=V(28*u,0,10*u),rk=V(-54*u,0,0),
			lh=V(-6*u,0,-10*u),lk=V(-30*u,0,0),
		}
	end},
}

local Sets={
	[1]={cadence=0.62,idle=idle1,move=move1,fall=fall1,land=land1,swim=swim1,climb=climbPose,sit=sitPose,jumps=jumps1},
	[2]={cadence=0.55,idle=idle2,move=move2,fall=fall2,land=land2,swim=swim2,climb=climbPose,sit=sitPose,jumps=jumps2},
}
local Engine={index=0}
local activeIndex=1
local char,hum,rootPart,animate,animator,rig
local engaged=false
local paused=false
local cur={}
for _,k in ipairs(KEYS) do cur[k]=ZERO end
local c={t=0,phase=0,speed=0,rb=0,dirLean=1,turn=0,look=Vector2.zero,cl=0,p=0,fall=0,depth=0}
local clock,phase,cphase,rb,turn,drop=0,0,0,0,0,0
local look,lookTarget,nextLook=Vector2.zero,Vector2.zero,1
local jumpVi,jumpT,jumpDur,lastVi=nil,0,0.6,0
local airT,peakFall,landDepth=0,0,0
local wCur,wTarget=0,0
local landAge,landHold,landDur=99,0,0.4
local playedConn
local conns={}

Bus.EngineOn=function() return engaged end

local function getJoint(part,name)
	local p=char and char:WaitForChild(part,5)
	local m=p and p:WaitForChild(name,5)
	if m and m:IsA("Motor6D") then
		local base=baseOf(m)
		return {m=m,p=base.Position,rot=base.Rotation,base=base}
	end
end

local function buildRig(r15)
	local j={}
	if r15 then
		j.root=getJoint("LowerTorso","Root")
		j.waist=getJoint("UpperTorso","Waist")
		j.neck=getJoint("Head","Neck")
		j.rs=getJoint("RightUpperArm","RightShoulder")
		j.re=getJoint("RightLowerArm","RightElbow")
		j.ls=getJoint("LeftUpperArm","LeftShoulder")
		j.le=getJoint("LeftLowerArm","LeftElbow")
		j.rh=getJoint("RightUpperLeg","RightHip")
		j.rk=getJoint("RightLowerLeg","RightKnee")
		j.ra=getJoint("RightFoot","RightAnkle")
		j.lh=getJoint("LeftUpperLeg","LeftHip")
		j.lk=getJoint("LeftLowerLeg","LeftKnee")
		j.la=getJoint("LeftFoot","LeftAnkle")
	else
		j.root=getJoint("HumanoidRootPart","RootJoint")
		j.neck=getJoint("Torso","Neck")
		j.rs=getJoint("Torso","Right Shoulder")
		j.ls=getJoint("Torso","Left Shoulder")
		j.rh=getJoint("Torso","Right Hip")
		j.lh=getJoint("Torso","Left Hip")
	end
	return {r15=r15,j=j}
end

local function writeJoint(j,rot,pos,pre)
	if not j or not j.m.Parent then return end
	local p=pos and (j.p+pos) or j.p
	j.m.C0=CFrame.new(p)*pre*CFrame.Angles(rad(rot.X),rad(rot.Y),rad(rot.Z))*j.rot
end

local function restoreJoints()
	if not rig then return end
	for _,jj in pairs(rig.j) do
		if jj.m.Parent then jj.m.C0=jj.base end
	end
end

local function apply(w,flip)
	local j=rig.j
	local id=CFrame.identity
	local pre=CFrame.Angles(rad(flip.X),rad(flip.Y),rad(flip.Z))
	local pos=V(0,-drop*w,0)
	local root,waist,neck=cur.root*w,cur.waist*w,cur.neck*w
	local rs,re,ls,le=cur.rs*w,cur.re*w,cur.ls*w,cur.le*w
	local rh,rk,lh,lk=cur.rh*w,cur.rk*w,cur.lh*w,cur.lk*w
	if rig.r15 then
		writeJoint(j.root,root,pos,pre)
		writeJoint(j.waist,waist,nil,id)
		writeJoint(j.neck,neck,nil,id)
		writeJoint(j.rs,rs,nil,id)
		writeJoint(j.re,re,nil,id)
		writeJoint(j.ls,ls,nil,id)
		writeJoint(j.le,le,nil,id)
		writeJoint(j.rh,rh,nil,id)
		writeJoint(j.rk,rk,nil,id)
		writeJoint(j.lh,lh,nil,id)
		writeJoint(j.lk,lk,nil,id)
		writeJoint(j.ra,V(-(rh.X+rk.X)*0.7,0,0),nil,id)
		writeJoint(j.la,V(-(lh.X+lk.X)*0.7,0,0),nil,id)
	else
		writeJoint(j.root,root+waist,pos,pre)
		writeJoint(j.neck,neck,nil,id)
		writeJoint(j.rs,rs,nil,id)
		writeJoint(j.ls,ls,nil,id)
		writeJoint(j.rh,rh-waist,nil,id)
		writeJoint(j.lh,lh-waist,nil,id)
	end
end

local function landWeight()
	local x=(landAge-landHold)/landDur
	if x<=0 then return 1 end
	if x>=1 then return 0 end
	return 1-TweenService:GetValue(x,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
end

local function release()
	if not engaged then return end
	engaged=false
	paused=false
	RunService:UnbindFromRenderStep("AnimHubMotion")
	if playedConn then
		playedConn:Disconnect()
		playedConn=nil
	end
	restoreJoints()
	for _,k in ipairs(KEYS) do cur[k]=ZERO end
	drop=0
	jumpVi=nil
	landAge=99
	local sl=Bus.SpiderLocked
	if animate and animate.Parent then animate.Disabled=(sl and sl()) or false end
end

local function update(dt)
	if not engaged or not rig or not hum or hum.Health<=0 or not rootPart or not rootPart.Parent then return end
	local busy=Bus.SpiderBusy
	if busy and busy() then
		if not paused then
			paused=true
			restoreJoints()
			for _,k in ipairs(KEYS) do cur[k]=ZERO end
			drop=0
			wCur=0
			jumpVi=nil
			landAge=99
		end
		return
	end
	paused=false
	dt=min(dt,0.1)
	clock+=dt
	wCur+=(wTarget-wCur)*(1-exp(-9*dt))
	if wTarget==0 and wCur<0.01 then
		release()
		return
	end
	landAge+=dt
	local set=Sets[activeIndex]
	local st=hum:GetState()
	local v=rootPart.AssemblyLinearVelocity
	local hs=Vector3.new(v.X,0,v.Z).Magnitude
	local air=st==H.Jumping or st==H.Freefall
	local mode
	if st==H.Swimming then mode="swim"
	elseif st==H.Climbing then mode="climb"
	elseif st==H.Seated then mode="sit"
	elseif air then
		if jumpVi and jumpT<jumpDur then mode="jump" else mode="fall" end
	elseif hs>0.9 then mode="move"
	else mode="idle" end
	if mode~="jump" and mode~="fall" then jumpVi=nil end
	if air then
		airT+=dt
		peakFall=max(peakFall,-v.Y)
		if mode=="jump" then jumpT+=dt end
	elseif st~=H.Landed then
		airT=0
		peakFall=0
	end
	local rbT=clamp((hs-8)/6,0,1)
	rb+=(rbT-rb)*(1-exp(-8*dt))
	local dir=(hs>1 and v:Dot(rootPart.CFrame.LookVector)<-hs*0.3) and -1 or 1
	if mode=="move" then phase=(phase+dt*hs*set.cadence*dir)%(pi*2) end
	if mode=="climb" then cphase=(cphase+dt*abs(v.Y)*1.3)%(pi*2) end
	local turnT=mode=="move" and clamp(rootPart.AssemblyAngularVelocity.Y*5,-14,14)*rb or 0
	turn+=(turnT-turn)*(1-exp(-6*dt))
	nextLook-=dt
	if nextLook<=0 then
		nextLook=math.random(15,45)/10
		if math.random()<0.25 then
			lookTarget=Vector2.zero
		else
			lookTarget=Vector2.new(math.random(-42,42),math.random(-8,10))
		end
	end
	local lt=(mode=="idle" or mode=="sit") and lookTarget or Vector2.zero
	look=look:Lerp(lt,1-exp(-3*dt))
	c.t=clock
	c.phase=phase
	c.speed=hs
	c.rb=rb
	c.dirLean=dir>0 and 1 or -0.35
	c.turn=turn
	c.look=look
	c.cl=cphase
	c.p=jumpVi and clamp(jumpT/jumpDur,0,1) or 0
	c.fall=clamp(0.25-v.Y/60,0,1)
	c.depth=landDepth
	local tgt
	local flip=ZERO
	if mode=="idle" then tgt=set.idle(c)
	elseif mode=="move" then tgt=set.move(c)
	elseif mode=="jump" then
		local e=set.jumps[jumpVi] or set.jumps[1]
		tgt=e.pose(c.p,c)
		flip=e.flip*ease(c.p)
	elseif mode=="fall" then tgt=set.fall(c)
	elseif mode=="swim" then tgt=set.swim(c)
	elseif mode=="climb" then tgt=set.climb(c)
	else tgt=set.sit(c) end
	local lw=landWeight()
	if mode=="move" then lw*=(1-0.55*rb) end
	local grounded=mode=="idle" or mode=="move"
	if lw>0.002 and grounded then tgt=mix(tgt,set.land(c),lw) end
	local rate=mode=="idle" and 7 or (mode=="swim" and 9 or (mode=="move" and 22 or 16))
	if lw>0.05 then rate=22 end
	local a=1-exp(-rate*dt)
	for _,k in ipairs(KEYS) do
		cur[k]=cur[k]:Lerp(tgt[k] or ZERO,a)
	end
	local dT=0
	if grounded then
		local rh,rk,lh,lk=rad(cur.rh.X),rad(cur.rk.X),rad(cur.lh.X),rad(cur.lk.X)
		local dR,dL
		if rig.r15 then
			dR=(1-cos(rh))+(1-cos(rh+rk))
			dL=(1-cos(lh))+(1-cos(lh+lk))
		else
			dR=2*(1-cos(rh))
			dL=2*(1-cos(lh))
		end
		dT=min(dR,dL)*0.8
	end
	drop+=(dT-drop)*(1-exp(-18*dt))
	apply(wCur,flip)
end

local function stopTracks()
	if not animator then return end
	for _,tr in ipairs(animator:GetPlayingAnimationTracks()) do
		tr:Stop(0.1)
	end
end

local function acquire()
	if engaged or not rig then return end
	engaged=true
	wCur=0
	if animate then animate.Disabled=true end
	stopTracks()
	if animator then
		playedConn=animator.AnimationPlayed:Connect(function(tr)
			local pr=tr.Priority
			if pr==Enum.AnimationPriority.Core or pr==Enum.AnimationPriority.Idle or pr==Enum.AnimationPriority.Movement then
				tr:Stop(0)
			end
		end)
	end
	RunService:BindToRenderStep("AnimHubMotion",Enum.RenderPriority.Character.Value+1,update)
end

local function startJump()
	local set=Sets[activeIndex]
	local n=#set.jumps
	local vi=math.random(1,n)
	if n>1 and vi==lastVi then vi=vi%n+1 end
	lastVi=vi
	jumpVi=vi
	jumpT=0
	local v0=hum.UseJumpPower and hum.JumpPower or math.sqrt(2*workspace.Gravity*hum.JumpHeight)
	jumpDur=clamp(2*v0/workspace.Gravity*0.9,0.35,1.3)
	landAge=99
end

local function onLand()
	if peakFall>22 or airT>0.35 then
		landDepth=clamp((peakFall-24)/60,0,1)
		landAge=0
		landHold=lerp(0.02,0.16,landDepth)
		landDur=lerp(0.32,0.7,landDepth)
	end
	airT=0
	peakFall=0
	jumpVi=nil
end

local function teardown()
	if engaged then
		RunService:UnbindFromRenderStep("AnimHubMotion")
	end
	engaged=false
	paused=false
	if playedConn then
		playedConn:Disconnect()
		playedConn=nil
	end
	for _,cn in ipairs(conns) do cn:Disconnect() end
	table.clear(conns)
	landAge=99
	wCur=0
	rig,char,hum,rootPart,animate,animator=nil,nil,nil,nil,nil,nil
	jumpVi=nil
	drop=0
	for _,k in ipairs(KEYS) do cur[k]=ZERO end
end

local function setup(newChar)
	teardown()
	char=newChar
	local h=newChar:WaitForChild("Humanoid",10)
	local hrp=newChar:WaitForChild("HumanoidRootPart",10)
	if not h or not hrp or char~=newChar then return end
	hum=h
	rootPart=hrp
	animate=newChar:FindFirstChild("Animate") or newChar:WaitForChild("Animate",3)
	animator=h:FindFirstChildOfClass("Animator") or h:WaitForChild("Animator",3)
	local built=buildRig(h.RigType==Enum.HumanoidRigType.R15)
	if char~=newChar then return end
	rig=built
	conns[#conns+1]=hum.StateChanged:Connect(function(_,new)
		if not engaged then return end
		if new==H.Jumping then
			startJump()
		elseif new==H.Landed then
			onLand()
		end
	end)
	if Engine.index>0 then
		wTarget=1
		acquire()
	end
end

function Engine.Set(index)
	Engine.index=index
	if index>0 then
		activeIndex=index
		wTarget=1
		acquire()
	else
		wTarget=0
		if not engaged or not hum or hum.Health<=0 then release() end
	end
end

function Engine.Shutdown()
	Engine.index=0
	wTarget=0
	wCur=0
	release()
end

function Engine.Destroy()
	Engine.Shutdown()
	teardown()
end

if player.Character then task.spawn(setup,player.Character) end
track(player.CharacterAdded:Connect(function(ch) task.spawn(setup,ch) end))
track(player.CharacterRemoving:Connect(teardown))
Bus.Engine=Engine
end
do
local RED=Color3.fromRGB(226,32,48)
local DARK=Color3.fromRGB(12,12,16)
local GREY=Color3.fromRGB(34,34,44)
local OFFGREY=Color3.fromRGB(70,70,82)
local WHITE=Color3.fromRGB(255,255,255)
local IDENT=CFrame.new()

local CFG={
	SwingRange=500,
	SwingMaxTime=10,
	ShootCount=15,
	ShootRange=90,
	ShootDuration=14,
	BindDuration=4,
	CrawlSpeed=24,
	CrawlHover=1.7,
	CrawlRay=4.5,
	AimX=0.62,
	AimY=0.38,
	SoundVolume=0.8,
	UIVolume=0.7,
	Sounds={Shoot="rbxasset://sounds/swordslash.wav",Hit="rbxasset://sounds/snap.mp3"},
	UISounds={Click="rbxasset://sounds/button.wav",On="rbxasset://sounds/switch.wav",Off="rbxasset://sounds/switch.wav"},
}

local Speed={Swing=200,Shoot=70}

local UI={BtnScale=1,AimScale=1,LockAim=false,LockBtn=false}

local S={Power=true,Swing=true,Shoot=true,Crawl=true}
local Sp={}
local ctx=nil
local Active={}
local Ropes={}
local Wraps={}
local Pose={Mode=nil,FireUntil=0,Phase=0,Amp=0,Last=os.clock(),Active=false,IdleAt=0}

local fxFolder=Workspace:FindFirstChild("SpiderFX") or Instance.new("Folder")
fxFolder.Name="SpiderFX"
fxFolder.Parent=Workspace
fxFolder:ClearAllChildren()

local function newInstance(class,props,parent)
	local o=Instance.new(class)
	for k,v in pairs(props) do o[k]=v end
	o.Parent=parent
	return o
end

local function playSound(id,parent,pitch)
	if not parent or not parent.Parent then return end
	local s=newInstance("Sound",{SoundId=id,Volume=CFG.SoundVolume,PlaybackSpeed=pitch or 1,RollOffMaxDistance=200},parent)
	s:Play()
	Debris:AddItem(s,4)
end

local function stopSkill(n)
	local f=Active[n]
	if f then
		Active[n]=nil
		f()
	end
end

local function stopAll(except)
	for n in pairs(Active) do
		if n~=except then stopSkill(n) end
	end
end

local controls=nil
task.spawn(function()
	local ok,res=pcall(function()
		return require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
	end)
	if ok then controls=res end
end)

local function moveVector()
	if controls then
		local ok,v=pcall(function() return controls:GetMoveVector() end)
		if ok and typeof(v)=="Vector3" then return v end
	end
	local d=ctx and ctx.Hum.MoveDirection or Vector3.zero
	local cf=Workspace.CurrentCamera.CFrame
	return Vector3.new(cf.RightVector:Dot(d),0,-cf.LookVector:Dot(d))
end

local function lerpUnit(a,b,k)
	local r=a:Lerp(b,k)
	if r.Magnitude<1e-3 then return b end
	return r.Unit
end

local LIMBS={
	RA={"RightUpperArm","Right Arm"},
	LA={"LeftUpperArm","Left Arm"},
	RL={"RightUpperLeg","Right Leg"},
	LL={"LeftUpperLeg","Left Leg"},
	RE={"RightLowerArm"},
	LE={"LeftLowerArm"},
	RK={"RightLowerLeg"},
	LK={"LeftLowerLeg"},
	NK={"Head"},
	WA={"UpperTorso"},
}

local function collectJoints(char)
	local motors={}
	for _,d in ipairs(char:GetDescendants()) do
		if d:IsA("Motor6D") and d.Part1 then motors[d.Part1]=d end
	end
	local found={}
	for key,names in pairs(LIMBS) do
		for _,n in ipairs(names) do
			local part=char:FindFirstChild(n)
			local m=part and motors[part]
			if m then
				local base=baseOf(m)
				local rot=base-base.Position
				found[key]={Motor=m,Base=base,Rot=rot,Inv=rot:Inverse(),Cur=IDENT}
				break
			end
		end
	end
	return found
end

local function jointsOk()
	local J=ctx.Joints
	if not J then return false end
	local n=0
	for _,j in pairs(J) do
		n+=1
		if not j.Motor.Parent or not j.Motor:IsDescendantOf(ctx.Char) then return false end
	end
	return n>0
end

local function restoreJoints(J)
	for _,j in pairs(J) do
		j.Cur=IDENT
		if j.Motor.Parent then
			j.Motor.C0=j.Base
			j.Motor.Transform=IDENT
		end
	end
end

local function limb(f,a)
	return CFrame.Angles(f,0,0)*CFrame.Angles(0,0,a)
end

local function poseTargets(mode,now)
	local T={}
	local p,amp=Pose.Phase,Pose.Amp
	if mode=="crawl" then
		local s1,s2=math.sin(p),math.sin(p+math.pi)
		local idle=math.sin(now*2)*0.05*(1-amp)
		T.RA=limb(2.45+s1*0.55*amp+idle,0.55)
		T.LA=limb(2.45+s2*0.55*amp-idle,-0.55)
		T.RL=limb(0.55+s2*0.55*amp,0.55)
		T.LL=limb(0.55+s1*0.55*amp,-0.55)
		T.RE=CFrame.Angles(0.35+0.45*math.max(0,s1)*amp,0,0)
		T.LE=CFrame.Angles(0.35+0.45*math.max(0,s2)*amp,0,0)
		T.RK=CFrame.Angles(-(0.9+0.55*math.max(0,s2)*amp),0,0)
		T.LK=CFrame.Angles(-(0.9+0.55*math.max(0,s1)*amp),0,0)
		T.NK=CFrame.Angles(0.85,0,0)
		T.WA=CFrame.Angles(0,0.16*s1*amp,0)
	elseif mode=="swing" then
		local sp=amp
		local sway=math.sin(now*5)*0.08
		T.RA=limb(2.85+sway,0.12)
		T.LA=limb(-0.5+sway,-0.45)
		T.RL=limb(0.95-0.7*sp,0.12)
		T.LL=limb(-0.45-0.2*sp,-0.15)
		T.RK=CFrame.Angles(-(1.1-0.5*sp),0,0)
		T.LK=CFrame.Angles(-(0.4+0.3*sp),0,0)
		T.RE=CFrame.Angles(0.15,0,0)
		T.LE=CFrame.Angles(0.5,0,0)
		T.NK=CFrame.Angles(0.55,0,0)
	elseif mode=="hover" then
		local bob=math.sin(now*2.2)*0.06
		local s1,s2=math.sin(p),math.sin(p+math.pi)
		T.RA=limb(2.75+bob,0.75)
		T.LA=limb(2.75-bob,-0.75)
		T.RL=limb(0.15+s1*0.7*amp,0.2)
		T.LL=limb(0.15+s2*0.7*amp,-0.2)
		T.RK=CFrame.Angles(-(0.4+0.5*math.max(0,s2)*amp),0,0)
		T.LK=CFrame.Angles(-(0.4+0.5*math.max(0,s1)*amp),0,0)
		T.RE=CFrame.Angles(0.2,0,0)
		T.LE=CFrame.Angles(0.2,0,0)
		T.NK=CFrame.Angles(0.3,0,0)
	else
		T.RA=limb(1.9,0.1)
	end
	return T
end

local function applyPose()
	local now=os.clock()
	local dt=math.min(now-Pose.Last,0.1)
	Pose.Last=now
	if not ctx or not ctx.Alive then return end
	if not jointsOk() then ctx.Joints=collectJoints(ctx.Char) end
	local J=ctx.Joints
	local mode=Pose.Mode
	if mode or now<Pose.FireUntil then
		Pose.Active=true
		Pose.IdleAt=now
		local T=poseTargets(mode,now)
		local k=1-math.exp(-dt*12)
		for key,j in pairs(J) do
			j.Cur=j.Cur:Lerp(T[key] or IDENT,k)
			j.Motor.C0=j.Base*(j.Inv*j.Cur*j.Rot)
			j.Motor.Transform=IDENT
		end
	elseif Pose.Active then
		local k=1-math.exp(-dt*10)
		for _,j in pairs(J) do
			j.Cur=j.Cur:Lerp(IDENT,k)
			j.Motor.C0=j.Base*(j.Inv*j.Cur*j.Rot)
		end
		if now-Pose.IdleAt>0.45 then
			restoreJoints(J)
			Pose.Active=false
		end
	end
end

pcall(function() RunService:UnbindFromRenderStep("SpiderPose") end)
RunService:BindToRenderStep("SpiderPose",Enum.RenderPriority.Last.Value,applyPose)

local function stopTracks()
	local an=ctx and ctx.Animator
	if an then
		for _,t in ipairs(an:GetPlayingAnimationTracks()) do t:Stop(0) end
	end
end

local function lockAnim(on)
	if not ctx or on==ctx.Locked then return end
	ctx.Locked=on
	local scr=ctx.Char:FindFirstChild("Animate")
	if scr then scr.Disabled=on or Bus.EngineOn() end
	if ctx.LockConn then
		ctx.LockConn:Disconnect()
		ctx.LockConn=nil
	end
	if on then
		stopTracks()
		if ctx.Animator then
			ctx.LockConn=ctx.Animator.AnimationPlayed:Connect(function(t) t:Stop(0) end)
		end
	end
end

local function ensureAlign()
	if not ctx.Align or not ctx.Align.Parent then
		local a0=newInstance("Attachment",{Name="SpiderAlignAtt"},ctx.Root)
		ctx.Align=newInstance("AlignOrientation",{
			Mode=Enum.OrientationAlignmentMode.OneAttachment,
			Attachment0=a0,
			RigidityEnabled=false,
			MaxTorque=1e7,
			MaxAngularVelocity=200,
			Responsiveness=28,
		},ctx.Root)
	end
	ctx.Align.Enabled=true
	return ctx.Align
end

local function takeControl()
	if not ctx or not ctx.Hum.Parent then return end
	ctx.Hum.PlatformStand=true
	ctx.Hum.AutoRotate=false
	lockAnim(true)
	local a=ensureAlign()
	a.CFrame=ctx.Root.CFrame.Rotation
end

local function releaseControl()
	if not ctx then return end
	if ctx.Align and ctx.Align.Parent then ctx.Align.Enabled=false end
	lockAnim(false)
	if ctx.Hum and ctx.Hum.Parent then
		ctx.Hum.PlatformStand=false
		ctx.Hum.AutoRotate=true
		ctx.Hum:ChangeState(Enum.HumanoidStateType.Freefall)
	end
end

local function makeLV(root,name)
	local att=newInstance("Attachment",{Name=name},root)
	local lv=newInstance("LinearVelocity",{
		Attachment0=att,
		MaxForce=1e8,
		RelativeTo=Enum.ActuatorRelativeTo.World,
		VelocityConstraintMode=Enum.VelocityConstraintMode.Vector,
		VectorVelocity=Vector3.zero,
	},root)
	return att,lv
end

Bus.SpiderLocked=function()
	return ctx~=nil and ctx.Locked==true
end

Bus.SpiderBusy=function()
	if not ctx or not ctx.Alive then return false end
	return ctx.Locked==true or Pose.Mode~=nil or Pose.Active==true or os.clock()<Pose.FireUntil
end
local SILK=Color3.fromRGB(244,247,255)
local SILK_GLOW=Color3.fromRGB(190,210,255)

local function newAnchor(pos)
	local a=Instance.new("Attachment")
	a.Parent=Workspace.Terrain
	a.WorldPosition=pos
	return a
end

local function makeBeam(a0,a1,w0,w1,transparency,color,emission,segments,parent)
	return newInstance("Beam",{
		Attachment0=a0,Attachment1=a1,
		Color=ColorSequence.new(color),
		Width0=w0,Width1=w1,
		Transparency=NumberSequence.new(transparency),
		FaceCamera=true,LightEmission=emission,LightInfluence=0,
		Segments=segments,CurveSize0=0,CurveSize1=0,
	},parent or fxFolder)
end

local function webSplat(pos,normal,radius)
	local n=normal.Magnitude>0.1 and normal.Unit or Vector3.yAxis
	local ref=math.abs(n.Y)<0.9 and Vector3.yAxis or Vector3.xAxis
	local u=n:Cross(ref).Unit
	local v=n:Cross(u)
	local base=pos+n*0.06
	local folder=newInstance("Folder",{Name="WebSplat"},fxFolder)
	local center=newAnchor(base)
	local atts={center}
	local beams={}
	local rings={0.45,1}
	local pts={}
	for k,rf in ipairs(rings) do
		pts[k]={}
		for i=1,8 do
			local a=i/8*math.pi*2
			local rr=rf*radius*(0.9+math.random()*0.2)
			local att=newAnchor(base+(u*math.cos(a)+v*math.sin(a))*rr)
			pts[k][i]=att
			table.insert(atts,att)
		end
	end
	for i=1,8 do
		table.insert(beams,makeBeam(center,pts[1][i],0.04,0.03,0.12,SILK,0.4,1,folder))
		table.insert(beams,makeBeam(pts[1][i],pts[2][i],0.035,0.025,0.12,SILK,0.4,1,folder))
		for k=1,2 do
			table.insert(beams,makeBeam(pts[k][i],pts[k][i%8+1],0.03,0.03,0.12,SILK,0.4,1,folder))
		end
	end
	task.spawn(function()
		local t0=os.clock()
		local life=1.6
		while folder.Parent do
			local k=(os.clock()-t0)/life
			if k>=1 then break end
			local tr=k<0.5 and 0.12 or 0.12+(k-0.5)/0.5*0.88
			for _,b in ipairs(beams) do b.Transparency=NumberSequence.new(tr) end
			task.wait(0.05)
		end
		folder:Destroy()
		for _,a in ipairs(atts) do a:Destroy() end
	end)
end

local function hitEffect(pos,normal,splat)
	local a=newAnchor(pos)
	local sparks=newInstance("ParticleEmitter",{
		Rate=0,
		Lifetime=NumberRange.new(0.25,0.5),
		Speed=NumberRange.new(8,18),
		SpreadAngle=Vector2.new(180,180),
		Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.28),NumberSequenceKeypoint.new(1,0)}),
		Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.1),NumberSequenceKeypoint.new(1,1)}),
		Color=ColorSequence.new(SILK),
		LightEmission=0.8,
	},a)
	local flash=newInstance("ParticleEmitter",{
		Rate=0,
		Lifetime=NumberRange.new(0.12,0.18),
		Speed=NumberRange.new(0,0),
		Size=NumberSequence.new({NumberSequenceKeypoint.new(0,2),NumberSequenceKeypoint.new(1,0)}),
		Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.3),NumberSequenceKeypoint.new(1,1)}),
		Color=ColorSequence.new(SILK),
		LightEmission=1,
	},a)
	sparks:Emit(12)
	flash:Emit(1)
	Debris:AddItem(a,1)
	if splat and normal then webSplat(pos,normal,3.4) end
end

local function ropeEnd(r)
	if r.Part and r.Part.Parent and r.Offset then
		return r.Part.CFrame:PointToWorldSpace(r.Offset)
	end
	return r.Hit
end

local function destroyRope(r)
	r.Dead=true
	for _,k in ipairs({"Core","Glow","StrandA","StrandB","Tip"}) do
		if r[k] then
			r[k]:Destroy()
			r[k]=nil
		end
	end
end

local function retractRope(r)
	if r and not r.Dead then
		r.Retract=true
		r.OnArrive=nil
		if r.Trail then r.Trail.Enabled=false end
	end
end

local function newRope(origin,pos,part,width,speed,normal,splat,delay)
	local rope={
		Origin=origin,
		Tip=newAnchor(origin.WorldPosition),
		Hit=pos,
		Part=part,
		Offset=part and part.CFrame:PointToObjectSpace(pos) or nil,
		Normal=normal,
		Splat=splat,
		Alpha=0,Speed=speed,
		StartAt=delay and os.clock()+delay or 0,
		Seed=math.random()*6.28,
		Arrived=false,Dead=false,Retract=false,Slack=false,Taut=false,
	}
	rope.Glow=makeBeam(origin,rope.Tip,width*3,width*2.2,0.9,SILK_GLOW,0.7,12)
	rope.Core=makeBeam(origin,rope.Tip,width*0.9,width*0.7,0.04,SILK,0.35,14)
	rope.StrandA=makeBeam(origin,rope.Tip,width*0.42,width*0.34,0.12,SILK,0.3,24)
	rope.StrandB=makeBeam(origin,rope.Tip,width*0.42,width*0.34,0.12,SILK,0.3,24)
	rope.Trail=newInstance("ParticleEmitter",{
		Rate=60,
		Lifetime=NumberRange.new(0.2,0.35),
		Speed=NumberRange.new(0,1),
		SpreadAngle=Vector2.new(180,180),
		Rotation=NumberRange.new(0,360),
		Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.28),NumberSequenceKeypoint.new(1,0)}),
		Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.2),NumberSequenceKeypoint.new(1,1)}),
		Color=ColorSequence.new(SILK),
		LightEmission=0.8,
	},rope.Tip)
	table.insert(Ropes,rope)
	return rope
end

track(RunService.Heartbeat:Connect(function(dt)
	local now=os.clock()
	for i=#Ropes,1,-1 do
		local r=Ropes[i]
		if r.Dead then
			table.remove(Ropes,i)
		elseif not r.Origin.Parent then
			destroyRope(r)
			table.remove(Ropes,i)
		elseif now>=r.StartAt then
			local startPos=r.Origin.WorldPosition
			local endPos=ropeEnd(r)
			local len=math.max((endPos-startPos).Magnitude,1)
			if r.Retract then
				r.Alpha-=dt*10
			elseif not r.Arrived then
				r.Alpha+=dt*r.Speed/len
				if r.Alpha>=1 then
					r.Alpha=1
					r.Arrived=true
					r.ArrivedAt=now
					r.Trail.Enabled=false
					if not r.Miss then
						hitEffect(endPos,r.Normal,r.Splat)
						playSound(CFG.Sounds.Hit,r.Tip,1.1)
					end
					if r.OnArrive then task.spawn(r.OnArrive,r) end
				end
			end
			if r.Alpha<=0 then
				destroyRope(r)
				table.remove(Ropes,i)
			else
				r.Tip.WorldPosition=startPos:Lerp(endPos,r.Alpha)
				local amp,freq
				if r.Retract then
					amp=0.8
					freq=38
				elseif not r.Arrived then
					amp=0.3+0.7*(1-r.Alpha)
					freq=34
				elseif r.Slack then
					amp=0.7+0.3*math.sin(now*0.9+r.Seed)
					freq=3.4
				elseif r.Taut then
					amp=0.03+1.2*math.exp(-(now-r.ArrivedAt)*3)
					freq=42
				else
					amp=2*math.exp(-(now-r.ArrivedAt)*3)+0.03
					freq=38
				end
				amp*=math.clamp(len/50,0.3,1.6)
				local w=math.sin(now*freq+r.Seed)
				r.Core.CurveSize0=amp*0.2*w
				r.Core.CurveSize1=-amp*0.2*w
				r.Glow.CurveSize0=amp*0.2*w
				r.Glow.CurveSize1=-amp*0.2*w
				r.StrandA.CurveSize0=amp*w
				r.StrandA.CurveSize1=-amp*w
				r.StrandB.CurveSize0=-amp*w
				r.StrandB.CurveSize1=amp*w
			end
		end
	end
end))

local function wrapTarget(model)
	local fx=newInstance("Folder",{Name="WebWrap"},fxFolder)
	local atts={}
	newInstance("Highlight",{
		FillColor=WHITE,FillTransparency=0.5,
		OutlineColor=WHITE,OutlineTransparency=0.1,
		DepthMode=Enum.HighlightDepthMode.Occluded,
		Adornee=model,
	},fx)
	local list={}
	for _,part in ipairs(model:GetChildren()) do
		if part:IsA("BasePart") and part.Name~="HumanoidRootPart" then
			table.insert(list,part)
		end
	end
	local diag=#list<=8
	for _,part in ipairs(list) do
		local h=part.Size/2+Vector3.new(0.08,0.08,0.08)
		local corners={}
		for xi=-1,1,2 do
			for yi=-1,1,2 do
				for zi=-1,1,2 do
					local a=newInstance("Attachment",{Position=Vector3.new(h.X*xi,h.Y*yi,h.Z*zi)},part)
					table.insert(atts,a)
					table.insert(corners,{a,xi,yi,zi})
				end
			end
		end
		for i=1,#corners do
			for k=i+1,#corners do
				local ca,cb=corners[i],corners[k]
				local diff=(ca[2]~=cb[2] and 1 or 0)+(ca[3]~=cb[3] and 1 or 0)+(ca[4]~=cb[4] and 1 or 0)
				if diff==1 or (diag and diff==2 and ca[4]==cb[4]) then
					makeBeam(ca[1],cb[1],0.045,0.045,0.05,SILK,0.4,1,fx)
				end
			end
		end
	end
	return function()
		fx:Destroy()
		for _,a in ipairs(atts) do a:Destroy() end
	end
end

local function addWrap(model)
	local un=wrapTarget(model)
	local done=false
	local function fin()
		if done then return end
		done=true
		un()
		Wraps[fin]=nil
	end
	Wraps[fin]=true
	task.delay(CFG.BindDuration,fin)
	local hum=model:FindFirstChildOfClass("Humanoid")
	if hum then hum.Died:Connect(fin) end
	return fin
end

local function clearWraps()
	for fin in pairs(Wraps) do fin() end
end

local function rayParams(ignoreCollide)
	local key=ignoreCollide and "PQ" or "PC"
	local p=ctx[key]
	if not p then
		p=RaycastParams.new()
		p.FilterType=Enum.RaycastFilterType.Exclude
		p.FilterDescendantsInstances={ctx.Char,fxFolder}
		p.IgnoreWater=true
		p.RespectCanCollide=not ignoreCollide
		ctx[key]=p
	end
	return p
end

local OFFSETS={Vector2.zero,Vector2.new(40,0),Vector2.new(-40,0),Vector2.new(0,-40),Vector2.new(0,40),Vector2.new(90,-90),Vector2.new(-90,-90)}

local function aimPoint()
	local vp=Workspace.CurrentCamera.ViewportSize
	if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
		return Vector2.new(vp.X*CFG.AimX,vp.Y*CFG.AimY)
	end
	return UserInputService:GetMouseLocation()
end

local function aimRay(offset)
	local p=aimPoint()+offset
	return Workspace.CurrentCamera:ViewportPointToRay(p.X,p.Y)
end

local function findTarget(range)
	local params=rayParams(true)
	local rootPos=ctx.Root.Position
	for _,o in ipairs(OFFSETS) do
		local r=aimRay(o)
		local res=Workspace:Raycast(r.Origin,r.Direction.Unit*(range+200),params)
		if res and (res.Position-rootPos).Magnitude<=range then return res end
	end
	return nil
end

local function resolveTarget(inst)
	local m=inst:FindFirstAncestorOfClass("Model")
	while m do
		if m:FindFirstChildOfClass("Humanoid") then return m end
		m=m:FindFirstAncestorOfClass("Model")
	end
	return nil
end
local function weldTo(arm,p)
	local w=Instance.new("WeldConstraint")
	w.Part0=arm
	w.Part1=p
	w.Parent=p
end

local function braceletPart(folder,arm,cf,size,color,shape,material)
	local p=newInstance("Part",{
		Size=size,Color=color,
		Material=material or Enum.Material.SmoothPlastic,
		Shape=shape or Enum.PartType.Block,
		CanCollide=false,CanQuery=false,CanTouch=false,
		Massless=true,Anchored=false,CastShadow=false,
		CFrame=cf,
	},folder)
	weldTo(arm,p)
	return p
end

local function buildBracelet(char,r15)
	local armName=r15 and "RightLowerArm" or "Right Arm"
	local arm=char:FindFirstChild(armName) or char:WaitForChild(armName,5)
	if not arm then return nil end
	local old=char:FindFirstChild("SpiderBracelet")
	if old then old:Destroy() end
	local y=r15 and -0.3 or -0.6
	local d=r15 and 1.28 or 1.34
	local folder=newInstance("Folder",{Name="SpiderBracelet"},char)
	local base=arm.CFrame*CFrame.new(0,y,0)
	local axisY=CFrame.Angles(0,0,math.rad(90))
	local cyl=Enum.PartType.Cylinder
	local ball=Enum.PartType.Ball
	local neon=Enum.Material.Neon
	braceletPart(folder,arm,base*axisY,Vector3.new(0.46,d,d),DARK,cyl)
	braceletPart(folder,arm,base*CFrame.new(0,0.23,0)*axisY,Vector3.new(0.07,d+0.05,d+0.05),RED,cyl,neon)
	braceletPart(folder,arm,base*CFrame.new(0,-0.23,0)*axisY,Vector3.new(0.07,d+0.05,d+0.05),RED,cyl,neon)
	local face=braceletPart(folder,arm,base*CFrame.new(d/2+0.03,0,0),Vector3.new(0.12,0.98,0.98),DARK,cyl)
	local emb=base*CFrame.new(d/2+0.105,0,0)
	braceletPart(folder,arm,emb*CFrame.new(0,-0.08,0),Vector3.new(0.26,0.26,0.26),RED,ball,neon)
	braceletPart(folder,arm,emb*CFrame.new(0,0.12,0),Vector3.new(0.15,0.15,0.15),RED,ball,neon)
	for _,s in ipairs({-1,1}) do
		for _,phi in ipairs({-0.95,-0.32,0.32,0.95}) do
			braceletPart(folder,arm,emb*CFrame.Angles(phi,0,0)*CFrame.new(0,0,s*0.22),Vector3.new(0.035,0.035,0.36),RED,Enum.PartType.Block,neon)
		end
	end
	local att=newInstance("Attachment",{Name="SpiderHandAtt",Position=Vector3.new(0.1,0,0)},face)
	local flash=newInstance("ParticleEmitter",{
		Rate=0,
		Lifetime=NumberRange.new(0.15,0.3),
		Speed=NumberRange.new(2,8),
		SpreadAngle=Vector2.new(60,60),
		Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.5),NumberSequenceKeypoint.new(1,0)}),
		Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.1),NumberSequenceKeypoint.new(1,1)}),
		Color=ColorSequence.new(SILK),
		LightEmission=0.9,
	},att)
	return att,flash
end

local function ensureBracelet()
	if not ctx then return false end
	if ctx.HandAtt and ctx.HandAtt.Parent and ctx.HandAtt:IsDescendantOf(ctx.Char) then return true end
	local att,flash=buildBracelet(ctx.Char,ctx.Rig=="R15")
	if not att then return false end
	ctx.HandAtt=att
	ctx.Flash=flash
	return true
end

local Swing={State=nil}
local Shoot={State=nil}

local function endSwing(keep)
	local st=Swing.State
	if not st then return end
	Swing.State=nil
	Active.Swing=nil
	if st.Conn then st.Conn:Disconnect() end
	retractRope(st.Rope)
	local vel
	if st.LV then
		vel=st.LV.VectorVelocity
		st.LV:Destroy()
	end
	if st.LVAtt then st.LVAtt:Destroy() end
	if not keep then
		if st.Control then
			releaseControl()
			if vel and ctx and ctx.Alive and ctx.Root.Parent then
				ctx.Root.AssemblyLinearVelocity=vel
			end
		end
		if Pose.Mode=="swing" then Pose.Mode=nil end
		Pose.Amp=0
	end
end

local function fireSwing(forced)
	if not ctx or not ctx.Alive or not S.Power or not S.Swing then return end
	if not ensureBracelet() then return end
	local res=forced or findTarget(CFG.SwingRange)
	if not res then return end
	stopAll("Swing")
	local model=resolveTarget(res.Instance)
	if model==ctx.Char then model=nil end
	local st={Model=model,Born=os.clock(),Alpha=0.25,Roll=0,Face=nil,Control=false,L=20,MinL=10,Dir=Vector3.zAxis,NextKick=0}
	local old=Swing.State
	if old then
		st.LV,st.LVAtt,st.Control=old.LV,old.LVAtt,old.Control
		st.Alpha=old.Alpha or 0.25
		st.Face=old.Face
		old.LV,old.LVAtt,old.Control=nil,nil,false
	end
	endSwing(true)
	local rope=newRope(ctx.HandAtt,res.Position,res.Instance,0.14,math.max(450,Speed.Swing*1.5),res.Normal,model==nil)
	st.Rope=rope
	Swing.State=st
	Active.Swing=function() endSwing(false) end
	Pose.FireUntil=os.clock()+0.45
	ctx.Flash:Emit(10)
	playSound(CFG.Sounds.Shoot,ctx.Root,1)
	rope.OnArrive=function()
		if Swing.State~=st then return end
		st.Arrive=os.clock()
		local root=ctx.Root
		local anchor=ropeEnd(rope)
		local toA=anchor-root.Position
		local flatDir=Vector3.new(toA.X,0,toA.Z)
		st.Dir=flatDir.Magnitude>0.1 and flatDir.Unit or root.CFrame.LookVector
		st.L=math.max(toA.Magnitude,st.MinL)
		if not st.Control then
			local v=root.AssemblyLinearVelocity
			if ctx.Hum.FloorMaterial~=Enum.Material.Air then v+=Vector3.new(0,28,0) end
			v+=st.Dir*math.min(Speed.Swing*0.1,20)
			takeControl()
			st.Control=true
			st.LVAtt,st.LV=makeLV(root,"SpiderSwingAtt")
			st.LV.VectorVelocity=v
		end
		rope.Taut=true
		Pose.Mode="swing"
		if model then addWrap(model) end
	end
	st.Conn=RunService.PreSimulation:Connect(function(dt)
		if not ctx or not ctx.Alive then endSwing(false) return end
		if rope.Dead then endSwing(false) return end
		local now=os.clock()
		if rope.Part and not rope.Part.Parent then endSwing(false) return end
		if st.Model then
			local h=st.Model:FindFirstChildOfClass("Humanoid")
			if not st.Model.Parent or not h or h.Health<=0 then endSwing(false) return end
		end
		local root=ctx.Root
		if not st.Arrive then
			if st.Control and st.LV then
				local v0=root.AssemblyLinearVelocity
				st.LV.VectorVelocity=v0*(1-math.min(dt*0.4,1))+Vector3.new(0,-Workspace.Gravity*0.2*dt,0)
			end
			if now-st.Born>2 then endSwing(false) end
			return
		end
		if now-st.Arrive>CFG.SwingMaxTime then endSwing(false) return end
		local pos=root.Position
		local anchor=ropeEnd(rope)
		local mx=Speed.Swing
		local v=root.AssemblyLinearVelocity
		local dist=(anchor-pos).Magnitude
		if st.Model then
			local stopDist=math.max(6,v.Magnitude*dt*1.3)
			if dist<=stopDist then
				st.LV.VectorVelocity=v*0.15
				endSwing(false)
				return
			end
			st.L=math.max(st.L-math.clamp(mx*0.25,10,120)*dt,st.MinL)
		elseif now-st.Arrive>0.6 and (pos-anchor):Dot(st.Dir)>st.L*0.6 then
			st.LV.VectorVelocity=v
			endSwing(false)
			return
		end
		if st.Impulse then
			v+=st.Impulse
			st.Impulse=nil
		end
		v+=Vector3.new(0,-Workspace.Gravity*dt,0)
		v*=1-math.min(dt*0.03,1)
		local mv=moveVector()
		if math.abs(mv.X)>0.1 then
			local cam=Workspace.CurrentCamera.CFrame
			local rg=Vector3.new(cam.RightVector.X,0,cam.RightVector.Z)
			if rg.Magnitude>0.01 then v+=rg.Unit*mv.X*25*dt end
		end
		if mv.Z<-0.1 and v.Magnitude>1 then v+=v.Unit*(-mv.Z)*20*dt end
		local off=pos+v*dt-anchor
		local d=off.Magnitude
		if d>st.L and d>1e-3 then
			local n=off/d
			local vr=v:Dot(n)
			if vr>0 then v-=n*vr end
			v-=n*math.min((d-st.L)/math.max(dt,1e-3),60)*0.5
		end
		if v.Magnitude>mx then v=v.Unit*mx end
		st.LV.VectorVelocity=v
		local flat=Vector3.new(v.X,0,v.Z)
		local s01=math.clamp(v.Magnitude/math.max(math.min(mx,160),1),0,1)
		Pose.Amp=s01
		if flat.Magnitude>3 then
			local face=flat.Unit
			local elev=math.atan2(v.Y,flat.Magnitude)
			local aT=math.clamp(0.25+(math.pi/2-elev)*0.5*s01,0.2,1.25)
			st.Alpha+=(aT-st.Alpha)*(1-math.exp(-dt*5))
			if st.Face then
				local yr=st.Face:Cross(face).Y/math.max(dt,1e-3)
				st.Roll+=(math.clamp(yr*0.3,-0.7,0.7)-st.Roll)*(1-math.exp(-dt*4))
				st.Face=lerpUnit(st.Face,face,1-math.exp(-dt*8))
			else
				st.Face=face
			end
			if ctx.Align then
				ctx.Align.CFrame=CFrame.lookAt(Vector3.zero,st.Face)*CFrame.Angles(-st.Alpha,0,st.Roll)
			end
		end
	end)
end
local function endShoot()
	local st=Shoot.State
	if not st then return end
	Shoot.State=nil
	Active.Shoot=nil
	if st.Conn then st.Conn:Disconnect() end
	for _,r in ipairs(st.Ropes) do retractRope(r) end
	local vel
	if st.LV then
		vel=st.LV.VectorVelocity
		st.LV:Destroy()
	end
	if st.LVAtt then st.LVAtt:Destroy() end
	if st.Control then
		releaseControl()
		if vel and ctx and ctx.Alive and ctx.Root.Parent then
			ctx.Root.AssemblyLinearVelocity=vel
		end
	end
	if Pose.Mode=="hover" then Pose.Mode=nil end
	Pose.Amp=0
end

local function fireShoot()
	if not ctx or not ctx.Alive or not S.Power or not S.Shoot then return end
	if Shoot.State then
		endShoot()
		return
	end
	if not ensureBracelet() then return end
	stopAll("Shoot")
	local root=ctx.Root
	local n=math.clamp(math.floor(CFG.ShootCount),12,19)
	local params=rayParams(false)
	local flat=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z)
	local st={Ropes={},Dirs={},Born=os.clock(),Control=false,Lean=0,Face=flat.Magnitude>0.05 and flat.Unit or Vector3.zAxis}
	Shoot.State=st
	Active.Shoot=function() endShoot() end
	Pose.FireUntil=os.clock()+0.45
	ctx.Flash:Emit(14)
	playSound(CFG.Sounds.Shoot,root,0.9)
	local ropeSpeed=math.max(150,Speed.Shoot*2)
	for i=0,n-1 do
		local y=0.85-(i/(n-1))*1.25
		local r=math.sqrt(1-y*y)
		local th=i*2.399963
		local dir=Vector3.new(math.cos(th)*r,y,math.sin(th)*r)
		local res=Workspace:Raycast(root.Position,dir*CFG.ShootRange,params)
		local delay=i*0.012
		local rope
		if res then
			rope=newRope(ctx.HandAtt,res.Position,res.Instance,0.08,ropeSpeed,res.Normal,false,delay)
			rope.Inst=res.Instance
		else
			rope=newRope(ctx.HandAtt,root.Position+dir*CFG.ShootRange*0.55,nil,0.08,ropeSpeed,nil,false,delay)
			rope.Miss=true
		end
		table.insert(st.Ropes,rope)
		table.insert(st.Dirs,dir)
	end
	st.Conn=RunService.PreSimulation:Connect(function(dt)
		if not ctx or not ctx.Alive then endShoot() return end
		local now=os.clock()
		if now-st.Born>CFG.ShootDuration then endShoot() return end
		local rt=ctx.Root
		local pos=rt.Position
		local arrived=0
		local k=1-math.exp(-dt*16)
		for i,r in ipairs(st.Ropes) do
			if r.Arrived and not r.Dead and not r.Retract then
				arrived+=1
				r.Part=nil
				r.Slack=true
				local dir=st.Dirs[i]
				local res=Workspace:Raycast(pos,dir*CFG.ShootRange,params)
				local goal
				if res then
					goal=res.Position
					r.Normal=res.Normal
				else
					goal=pos+dir*CFG.ShootRange*0.55
				end
				r.Hit=r.Hit:Lerp(goal,res and k or 1-math.exp(-dt*7))
			end
		end
		if arrived==0 then
			if now-st.Born>1.5 then endShoot() end
			return
		end
		if not st.Control then
			st.Control=true
			takeControl()
			Pose.Mode="hover"
			st.HoldY=pos.Y+3
			st.LVAtt,st.LV=makeLV(rt,"SpiderHoverAtt")
			st.LV.VectorVelocity=rt.AssemblyLinearVelocity
		end
		local mv=moveVector()
		local cam=Workspace.CurrentCamera.CFrame
		local fl=Vector3.new(cam.LookVector.X,0,cam.LookVector.Z)
		fl=fl.Magnitude>0.01 and fl.Unit or Vector3.zAxis
		local rg=Vector3.new(cam.RightVector.X,0,cam.RightVector.Z)
		rg=rg.Magnitude>0.01 and rg.Unit or Vector3.xAxis
		local move=rg*mv.X+fl*(-mv.Z)
		local mag=math.min(move.Magnitude,1)
		local dir=mag>0.05 and move.Unit or Vector3.zero
		local bob=math.sin(now*1.8)*1.2
		local vy=math.clamp((st.HoldY+bob-pos.Y)*4,-30,30)
		local desired=dir*Speed.Shoot*mag+Vector3.new(0,vy,0)
		st.LV.VectorVelocity=st.LV.VectorVelocity:Lerp(desired,1-math.exp(-dt*5))
		if mag>0.05 then st.Face=lerpUnit(st.Face,dir,1-math.exp(-dt*7)) end
		st.Lean+=(mag*0.4-st.Lean)*(1-math.exp(-dt*6))
		if ctx.Align then
			ctx.Align.CFrame=CFrame.lookAt(Vector3.zero,st.Face)*CFrame.Angles(-st.Lean,0,0)
		end
		Pose.Amp=mag
		Pose.Phase+=dt*(3+9*mag)
	end)
end

local function ropeReady()
	local st=Swing.State
	if st and st.Arrive then return true end
	local sh=Shoot.State
	if sh then
		for _,r in ipairs(sh.Ropes) do
			if r.Arrived and not r.Dead and not r.Retract and r.Inst then return true end
		end
	end
	return false
end

local function ropeAction()
	if not ctx or not ctx.Alive or not S.Power or not S.Swing then return end
	local st=Swing.State
	if st and st.Arrive then
		local now=os.clock()
		if now<st.NextKick then return end
		st.NextKick=now+0.3
		local v=ctx.Root.AssemblyLinearVelocity
		local d=v.Magnitude>2 and v.Unit or st.Dir
		st.Impulse=d*math.min(Speed.Swing*0.3,60)
		return
	end
	local sh=Shoot.State
	if not sh then return end
	local look=Workspace.CurrentCamera.CFrame.LookVector
	local rootPos=ctx.Root.Position
	local best,bestScore
	for _,r in ipairs(sh.Ropes) do
		if r.Arrived and not r.Dead and not r.Retract and r.Inst then
			local dv=r.Hit-rootPos
			if dv.Magnitude>8 then
				local score=dv.Unit:Dot(look)+(dv.Y>0 and 0.35 or 0)
				if not bestScore or score>bestScore then
					best,bestScore=r,score
				end
			end
		end
	end
	if best then
		fireSwing({Position=best.Hit,Instance=best.Inst,Normal=best.Normal or Vector3.yAxis})
	end
end

local Crawl={Conn=nil,Attached=false,Normal=Vector3.yAxis,Face=Vector3.zAxis,Lost=0,Cooldown=0}

local function safeUnit(v,fb)
	if v.Magnitude<1e-3 then return fb end
	return v.Unit
end

local function proj(v,n)
	return v-n*v:Dot(n)
end

local function crawlDetach()
	Crawl.Attached=false
	if Crawl.LV then Crawl.LV:Destroy() Crawl.LV=nil end
	if Crawl.LVAtt then Crawl.LVAtt:Destroy() Crawl.LVAtt=nil end
	if Pose.Mode=="crawl" then Pose.Mode=nil end
	Pose.Amp=0
	if ctx and ctx.Alive and ctx.Root.Parent then
		local root=ctx.Root
		local f=Vector3.new(Crawl.Face.X,0,Crawl.Face.Z)
		if f.Magnitude<0.1 then f=Vector3.new(-Crawl.Normal.X,0,-Crawl.Normal.Z) end
		if f.Magnitude<0.1 then f=Vector3.zAxis end
		local p=root.Position+Crawl.Normal*1.5
		root.CFrame=CFrame.lookAt(p,p+f.Unit)
		releaseControl()
	end
end

local function crawlOff()
	if Crawl.Conn then
		Crawl.Conn:Disconnect()
		Crawl.Conn=nil
	end
	Active.Crawl=nil
	if Crawl.Attached then crawlDetach() end
end

local function crawlAttach(res)
	Crawl.Attached=true
	Crawl.Normal=res.Normal
	Crawl.Lost=0
	local fallback=safeUnit(proj(ctx.Root.CFrame.LookVector,res.Normal),Vector3.zAxis)
	Crawl.Face=safeUnit(proj(Vector3.yAxis,res.Normal),fallback)
	takeControl()
	Crawl.LVAtt,Crawl.LV=makeLV(ctx.Root,"SpiderLVAtt")
	Pose.Phase=0
	Pose.Amp=0
	Pose.Mode="crawl"
end

local function crawlStep(dt)
	if not ctx or not ctx.Alive then crawlOff() return end
	local root=ctx.Root
	local pos=root.Position
	local params=rayParams(false)
	if not Crawl.Attached then
		if os.clock()<Crawl.Cooldown then return end
		local mv=moveVector()
		if mv.Magnitude<0.1 then return end
		local d=ctx.Hum.MoveDirection
		if d.Magnitude<0.1 then d=root.CFrame.LookVector end
		local res=Workspace:Raycast(pos,d.Unit*3.2,params)
		if res and res.Normal.Y<0.7 then
			crawlAttach(res)
		elseif ctx.Hum.FloorMaterial==Enum.Material.Air then
			local up=Workspace:Raycast(pos,Vector3.yAxis*4,params)
			if up and up.Normal.Y<-0.6 then crawlAttach(up) end
		end
		return
	end
	local N=Crawl.Normal
	local cam=Workspace.CurrentCamera.CFrame
	local pl=proj(cam.LookVector,N)
	local pu=proj(cam.UpVector,N)
	local w=math.clamp(pl.Magnitude*2,0,1)
	local fwd=safeUnit(safeUnit(pl,Vector3.zero)*w+safeUnit(pu,Vector3.zero)*(1-w),Crawl.Face)
	local right=safeUnit(fwd:Cross(N),Vector3.xAxis)
	local mv=moveVector()
	local move=right*mv.X+fwd*(-mv.Z)
	local mag=math.min(move.Magnitude,1)
	local dir=mag>0.05 and move.Unit or Vector3.zero
	local velocity=dir*CFG.CrawlSpeed*mag
	local res=Workspace:Raycast(pos,-N*CFG.CrawlRay,params)
	local targetN=res and res.Normal or N
	if mag>0.05 then
		local ahead=Workspace:Raycast(pos,dir*3.2,params)
		if ahead and ahead.Normal:Dot(N)<0.6 then
			targetN=ahead.Normal
			velocity=velocity*0.4
		elseif not res then
			local wrap=Workspace:Raycast(pos+dir*3-N*(CFG.CrawlHover+1.2),-dir*4,params)
			if wrap then targetN=wrap.Normal end
		end
	end
	if res or targetN~=N then Crawl.Lost=0 else Crawl.Lost+=dt end
	if Crawl.Lost>0.3 then
		crawlDetach()
		Crawl.Cooldown=os.clock()+0.5
		return
	end
	if targetN.Y>0.8 then
		crawlDetach()
		Crawl.Cooldown=os.clock()+0.5
		return
	end
	N=safeUnit(N:Lerp(targetN,1-math.exp(-dt*9)),N)
	local stick=Vector3.zero
	if res then
		stick=-N*math.clamp((res.Distance-CFG.CrawlHover)*12,-25,25)
	end
	Crawl.LV.VectorVelocity=velocity+stick
	local face=Crawl.Face
	if mag>0.05 then face=safeUnit(face:Lerp(dir,1-math.exp(-dt*10)),dir) end
	face=safeUnit(proj(face,N),fwd)
	Crawl.Face=face
	Crawl.Normal=N
	local r2=safeUnit((-N):Cross(face),Vector3.xAxis)
	ctx.Align.CFrame=CFrame.fromMatrix(Vector3.zero,r2,face,N)
	Pose.Amp+=(mag-Pose.Amp)*(1-math.exp(-dt*8))
	Pose.Phase+=dt*(mag>0.05 and (5+9*mag) or 1)
end

local function crawlOn()
	if not ctx or not ctx.Alive or not S.Power or not S.Crawl or Crawl.Conn then return end
	stopAll("Crawl")
	Crawl.Cooldown=0
	Active.Crawl=crawlOff
	Crawl.Conn=RunService.PreSimulation:Connect(crawlStep)
end

local function toggleCrawl()
	if Crawl.Conn then crawlOff() else crawlOn() end
end
local cgui=newInstance("ScreenGui",{
	Name="SpiderControlsGui",ResetOnSpawn=false,IgnoreGuiInset=true,
	DisplayOrder=50,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
},playerGui)

local uiSounds={}
for kind,id in pairs(CFG.UISounds) do
	uiSounds[kind]=newInstance("Sound",{Name="UI"..kind,SoundId=id,Volume=CFG.UIVolume},cgui)
end

local function uiSound(kind,pitch)
	local s=uiSounds[kind]
	if not s then return end
	s.PlaybackSpeed=pitch or 1
	s.TimePosition=0
	s:Play()
end

local function toggleSound(on)
	uiSound(on and "On" or "Off",on and 1.15 or 0.85)
end

local function round(o,r) return newInstance("UICorner",{CornerRadius=UDim.new(0,r)},o) end
local function circle(o) return newInstance("UICorner",{CornerRadius=UDim.new(0.5,0)},o) end
local function outline(o,c,t,tr) return newInstance("UIStroke",{Color=c,Thickness=t,Transparency=tr or 0,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},o) end
local function gradient(o,c0,c1,rot) return newInstance("UIGradient",{Color=ColorSequence.new(c0,c1),Rotation=rot or 90},o) end

local function label(parent,props)
	props.BackgroundTransparency=1
	props.TextScaled=true
	props.Font=props.Font or Enum.Font.GothamBold
	props.TextColor3=props.TextColor3 or WHITE
	return newInstance("TextLabel",props,parent)
end

local function clampPos(target,x,y,w,h)
	local vp=Workspace.CurrentCamera.ViewportSize
	local sz=target.AbsoluteSize
	w=w or sz.X
	h=h or sz.Y
	return UDim2.fromOffset(math.clamp(x,0,math.max(vp.X-w,0)),math.clamp(y,0,math.max(vp.Y-h,0)))
end

local function makeDraggable(target,handle,onTap,canDrag)
	local dragging=false
	local moved=false
	local startInput,startMouse,startX,startY
	local conns={}
	table.insert(conns,handle.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
			dragging=true
			moved=false
			startInput=input
			startMouse=input.Position
			startX=target.Position.X.Offset
			startY=target.Position.Y.Offset
		end
	end))
	table.insert(conns,UserInputService.InputChanged:Connect(function(input)
		if dragging and (input==startInput or input.UserInputType==Enum.UserInputType.MouseMovement) then
			if canDrag and not canDrag() then return end
			local d=input.Position-startMouse
			if d.Magnitude>8 then moved=true end
			if moved then target.Position=clampPos(target,startX+d.X,startY+d.Y) end
		end
	end))
	table.insert(conns,UserInputService.InputEnded:Connect(function(input)
		if dragging and (input==startInput or (input.UserInputType==Enum.UserInputType.MouseButton1 and startInput.UserInputType==Enum.UserInputType.MouseButton1)) then
			dragging=false
			if not moved and onTap then onTap() end
		end
	end))
	handle.Destroying:Connect(function()
		for _,c in ipairs(conns) do c:Disconnect() end
	end)
end

local touchFolder=newInstance("Folder",{Name="TouchControls"},cgui)
local touch={}
local touchUI={}
local touchBase={}
local touchPos={}
local last={}
local aimEdit=false
local syncTouch

local cross=newInstance("Frame",{
	Name="Crosshair",AnchorPoint=Vector2.new(0.5,0.5),
	Position=UDim2.fromScale(CFG.AimX,CFG.AimY),
	Size=UDim2.fromOffset(64,64),BackgroundTransparency=1,Visible=false,
},cgui)
local crossScale=newInstance("UIScale",{Scale=UI.AimScale},cross)
local editRing=newInstance("Frame",{
	AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
	Size=UDim2.fromScale(1,1),BackgroundColor3=RED,BackgroundTransparency=0.82,Visible=false,
},cross)
circle(editRing)
outline(editRing,WHITE,1.5,0.25)
local crossParts={}
local function crossBar(ax,ay,px,py,w,h)
	local f=newInstance("Frame",{
		AnchorPoint=Vector2.new(ax,ay),Position=UDim2.new(0.5,px,0.5,py),
		Size=UDim2.fromOffset(w,h),BackgroundColor3=WHITE,BorderSizePixel=0,
	},cross)
	outline(f,Color3.new(0,0,0),1,0.4)
	table.insert(crossParts,f)
end
crossBar(0.5,1,0,-6,2,9)
crossBar(0.5,0,0,6,2,9)
crossBar(1,0.5,-6,0,9,2)
crossBar(0,0.5,6,0,9,2)
crossBar(0.5,0.5,0,0,4,4)

local function paintCross(c)
	for _,f in ipairs(crossParts) do f.BackgroundColor3=c end
end

local function updateCross()
	cross.Position=UDim2.fromScale(CFG.AimX,CFG.AimY)
end

local function setAim(x,y)
	CFG.AimX=math.clamp(x,0.05,0.95)
	CFG.AimY=math.clamp(y,0.05,0.95)
	updateCross()
	if Sp.onAim then Sp.onAim(CFG.AimX,CFG.AimY) end
end

do
	local drag,startPos,sx,sy
	cross.InputBegan:Connect(function(i)
		if not aimEdit or UI.LockAim then return end
		if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
			drag=i
			startPos=i.Position
			sx,sy=CFG.AimX,CFG.AimY
		end
	end)
	track(UserInputService.InputChanged:Connect(function(i)
		if drag and not UI.LockAim and (i==drag or i.UserInputType==Enum.UserInputType.MouseMovement) then
			local vp=Workspace.CurrentCamera.ViewportSize
			local d=i.Position-startPos
			setAim(sx+d.X/vp.X,sy+d.Y/vp.Y)
		end
	end))
	track(UserInputService.InputEnded:Connect(function(i)
		if drag and (i==drag or (i.UserInputType==Enum.UserInputType.MouseButton1 and drag.UserInputType==Enum.UserInputType.MouseButton1)) then
			drag=nil
		end
	end))
end

local function resizeFloats()
	for key,holder in pairs(touch) do
		local base=touchBase[key]
		local ns=base*UI.BtnScale
		local cx=holder.Position.X.Offset+holder.Size.X.Offset/2
		local cy=holder.Position.Y.Offset+holder.Size.Y.Offset/2
		holder.Size=UDim2.fromOffset(ns,ns)
		holder.Position=clampPos(holder,cx-ns/2,cy-ns/2,ns,ns)
	end
end

local function refresh()
	local touchOnly=UserInputService.TouchEnabled and not UserInputService.MouseEnabled
	cross.Visible=aimEdit or (S.Power and touchOnly and (S.Swing or S.Shoot))
	cross.Active=aimEdit and not UI.LockAim
	editRing.Visible=aimEdit
	if syncTouch then syncTouch() end
end

local function setSkill(name,on)
	S[name]=on
	if not on then stopSkill(name) end
	refresh()
end

local function setPower(on)
	S.Power=on
	if not on then
		stopAll()
		clearWraps()
	end
	refresh()
end
local function jumpRect()
	local ok,r=pcall(function()
		local tg=playerGui:FindFirstChild("TouchGui")
		local frame=tg and tg:FindFirstChild("TouchControlFrame")
		local jb=frame and frame:FindFirstChild("JumpButton")
		if jb then return {jb.AbsolutePosition,jb.AbsoluteSize} end
		return nil
	end)
	if ok and r then return r[1],r[2] end
	local vp=Workspace.CurrentCamera.ViewportSize
	return Vector2.new(vp.X-120,vp.Y-120),Vector2.new(80,80)
end

local TOUCH={
	{Key="Swing",Text="SWING",Fire=function() fireSwing() end},
	{Key="Shoot",Text="SHOOT",Fire=function() fireShoot() end},
	{Key="Rope",Text="ĐU TƠ",Fire=function() ropeAction() end},
	{Key="Crawl",Text="WALL",Fire=function() toggleCrawl() end},
}

local function defaultTouchPos(key,s)
	local jp,js=jumpRect()
	if key=="Crawl" then
		return Vector2.new(jp.X-s-14,jp.Y+js.Y-s)
	elseif key=="Swing" then
		return Vector2.new(jp.X+(js.X-s)/2,jp.Y-s-14)
	elseif key=="Rope" then
		return Vector2.new(jp.X+(js.X-s)/2,math.max(jp.Y-2*s-28,10))
	end
	return Vector2.new(jp.X-s-14,jp.Y-s-14)
end

local function isActive(key)
	if key=="Swing" then return Swing.State~=nil end
	if key=="Shoot" then return Shoot.State~=nil end
	if key=="Rope" then return false end
	return Crawl.Conn~=nil
end

local function styleTouch(key,active)
	local u=touchUI[key]
	if not u then return end
	TweenService:Create(u.Btn,TweenInfo.new(0.2),{BackgroundColor3=active and RED or Color3.fromRGB(34,34,46)}):Play()
	TweenService:Create(u.Glow,TweenInfo.new(0.2),{BackgroundTransparency=active and 0.55 or 1}):Play()
	u.Stroke.Color=active and WHITE or RED
end

local function buildFloat(t,base,p)
	local s=base*UI.BtnScale
	local holder=newInstance("Frame",{
		Name=t.Key,BackgroundTransparency=1,
		Size=UDim2.fromOffset(s,s),Position=UDim2.fromOffset(p.X,p.Y),
	},touchFolder)
	local glow=newInstance("Frame",{
		AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
		Size=UDim2.fromScale(1.34,1.34),BackgroundColor3=RED,BackgroundTransparency=1,BorderSizePixel=0,
	},holder)
	circle(glow)
	local b=newInstance("TextButton",{
		AutoButtonColor=false,Text="",BorderSizePixel=0,
		AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromScale(1,1),
		BackgroundColor3=Color3.fromRGB(34,34,46),
	},holder)
	circle(b)
	gradient(b,WHITE,Color3.fromRGB(110,110,120),90)
	local stroke=outline(b,RED,2.5)
	local scale=newInstance("UIScale",{Scale=1},b)
	local ring=newInstance("Frame",{
		AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
		Size=UDim2.fromScale(0.84,0.84),BackgroundTransparency=1,
	},b)
	circle(ring)
	outline(ring,WHITE,1,0.82)
	label(b,{
		Text=t.Text,Font=Enum.Font.GothamBlack,
		AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.47),Size=UDim2.fromScale(0.7,0.26),
	})
	local bar=newInstance("Frame",{
		AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.72),
		Size=UDim2.fromScale(0.28,0.035),BackgroundColor3=RED,BorderSizePixel=0,
	},b)
	round(bar,2)
	b.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
			TweenService:Create(scale,TweenInfo.new(0.1),{Scale=0.88}):Play()
		end
	end)
	b.InputEnded:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
			TweenService:Create(scale,TweenInfo.new(0.16,Enum.EasingStyle.Back),{Scale=1}):Play()
		end
	end)
	touchUI[t.Key]={Btn=b,Glow=glow,Stroke=stroke}
	makeDraggable(holder,b,t.Fire,function() return not UI.LockBtn end)
	styleTouch(t.Key,isActive(t.Key))
	return holder
end

syncTouch=function()
	if not UserInputService.TouchEnabled then return end
	for _,t in ipairs(TOUCH) do
		local want
		if t.Key=="Rope" then
			want=S.Power and S.Swing and ropeReady()
		else
			want=S.Power and S[t.Key]
		end
		local b=touch[t.Key]
		if want and not b then
			local _,js=jumpRect()
			local base=math.clamp(js.X*0.8,52,92)
			touchBase[t.Key]=base
			local p=touchPos[t.Key] or defaultTouchPos(t.Key,base*UI.BtnScale)
			touch[t.Key]=buildFloat(t,base,p)
		elseif not want and b then
			touchPos[t.Key]=Vector2.new(b.Position.X.Offset,b.Position.Y.Offset)
			b:Destroy()
			touch[t.Key]=nil
			touchUI[t.Key]=nil
		end
	end
end

do
	local acc=0
	local lastRope=false
	track(RunService.Heartbeat:Connect(function(dt)
		acc+=dt
		if acc<0.15 then return end
		acc=0
		local rr=ropeReady()
		if rr~=lastRope then
			lastRope=rr
			syncTouch()
		end
		for _,key in ipairs({"Swing","Shoot","Crawl"}) do
			local active=isActive(key)
			if last[key]~=active then
				last[key]=active
				styleTouch(key,active)
			end
		end
		if cross.Visible and not aimEdit and ctx and ctx.Alive then
			paintCross(findTarget(CFG.SwingRange) and RED or WHITE)
		elseif aimEdit then
			paintCross(WHITE)
		end
	end))
end

track(UserInputService.InputBegan:Connect(function(input,gp)
	if gp or input.UserInputType~=Enum.UserInputType.Keyboard then return end
	local k=input.KeyCode
	if k==Enum.KeyCode.E then
		fireSwing()
	elseif k==Enum.KeyCode.Q then
		fireShoot()
	elseif k==Enum.KeyCode.F then
		ropeAction()
	elseif k==Enum.KeyCode.Z then
		toggleCrawl()
	elseif k==Enum.KeyCode.R then
		stopAll()
	end
end))

track(UserInputService.JumpRequest:Connect(function()
	if not ctx or not ctx.Alive then return end
	local root=ctx.Root
	if Crawl.Attached then
		local n=Crawl.Normal
		crawlDetach()
		Crawl.Cooldown=os.clock()+0.4
		root.AssemblyLinearVelocity=n*40+Vector3.new(0,30,0)
	elseif Swing.State then
		endSwing(false)
		root.AssemblyLinearVelocity=root.AssemblyLinearVelocity+Vector3.new(0,35,0)
	elseif Shoot.State then
		endShoot()
		root.AssemblyLinearVelocity=root.AssemblyLinearVelocity+Vector3.new(0,35,0)
	end
end))

local R15NEED={"UpperTorso","LowerTorso","Head","RightUpperArm","RightLowerArm","LeftUpperArm","LeftLowerArm","RightUpperLeg","RightLowerLeg","LeftUpperLeg","LeftLowerLeg","RightFoot","LeftFoot"}
local R6NEED={"Torso","Head","Right Arm","Left Arm","Right Leg","Left Leg"}

local function unbindChar()
	local old=ctx
	if not old then return end
	stopAll()
	old.Alive=false
	if old.LockConn then
		old.LockConn:Disconnect()
		old.LockConn=nil
	end
	if old.Died then old.Died:Disconnect() end
	if old.Joints then restoreJoints(old.Joints) end
	ctx=nil
	Pose.Mode=nil
	Pose.Active=false
	Pose.Amp=0
	Pose.FireUntil=0
	clearWraps()
end

local function bindChar(char)
	unbindChar()
	local hum=char:WaitForChild("Humanoid",10)
	local root=char:WaitForChild("HumanoidRootPart",10)
	if not hum or not root then return end
	local r15=hum.RigType==Enum.HumanoidRigType.R15
	for _,n in ipairs(r15 and R15NEED or R6NEED) do char:WaitForChild(n,5) end
	if player.Character~=char then return end
	local c={
		Char=char,Hum=hum,Root=root,
		Animator=hum:FindFirstChildOfClass("Animator") or hum:WaitForChild("Animator",3),
		Rig=r15 and "R15" or "R6",
		Alive=hum.Health>0,
		Joints=collectJoints(char),
	}
	c.Died=hum.Died:Connect(function()
		stopAll()
		c.Alive=false
	end)
	ctx=c
end

if player.Character then task.spawn(bindChar,player.Character) end
track(player.CharacterAdded:Connect(function(ch) task.spawn(bindChar,ch) end))
track(player.CharacterRemoving:Connect(unbindChar))

Sp.S,Sp.CFG,Sp.Speed,Sp.UI=S,CFG,Speed,UI
Sp.setSkill,Sp.setPower=setSkill,setPower
Sp.stopAll=stopAll
Sp.refresh=refresh
Sp.setAim=setAim
Sp.setAimEdit=function(v)
	aimEdit=v
	refresh()
end
Sp.setAimScale=function(v) crossScale.Scale=v end
Sp.resizeFloats=resizeFloats
Sp.toggleSound=toggleSound
Sp.Destroy=function()
	stopAll()
	clearWraps()
	for i=#Ropes,1,-1 do destroyRope(Ropes[i]) end
	table.clear(Ropes)
	if ctx then
		if ctx.Locked then releaseControl() end
		local br=ctx.Char:FindFirstChild("SpiderBracelet")
		if br then br:Destroy() end
	end
	unbindChar()
	pcall(function() RunService:UnbindFromRenderStep("SpiderPose") end)
	fxFolder:Destroy()
	cgui:Destroy()
end
Bus.Sp=Sp
task.delay(0.5,refresh)
end
do
local UIS,TS,RS=UserInputService,TweenService,RunService
local Sp,Engine=Bus.Sp,Bus.Engine
local S,CFG,Speed,UI=Sp.S,Sp.CFG,Sp.Speed,Sp.UI

local themes={
	Gold={Accent=Color3.fromRGB(255,184,28),AccentDark=Color3.fromRGB(72,52,10)},
	Red={Accent=Color3.fromRGB(240,50,60),AccentDark=Color3.fromRGB(80,16,22)},
	Blue={Accent=Color3.fromRGB(45,150,255),AccentDark=Color3.fromRGB(12,44,86)},
}
local T={
	Bg=Color3.fromRGB(10,10,14),
	Panel=Color3.fromRGB(18,18,25),
	Item=Color3.fromRGB(28,28,38),
	Line=Color3.fromRGB(54,54,70),
	Text=Color3.fromRGB(238,238,248),
	Sub=Color3.fromRGB(145,145,165),
	Off=Color3.fromRGB(62,62,80),
	Red=Color3.fromRGB(232,66,78),
	Accent=themes.Gold.Accent,
	AccentDark=themes.Gold.AccentDark,
}
local Glass={main=0.2}
local FX={on=true,border=true,shine=true}
local currentTheme="Gold"
local skins,glassSkins,grads,dotStrokes={},{},{},{}

local function skin(fn)
	table.insert(skins,fn)
	fn()
end
local function paint(obj,prop,key)
	skin(function() obj[prop]=T[key] end)
end
local function glass(obj,offset)
	local fn=function() obj.BackgroundTransparency=math.clamp(Glass.main+offset,0,1) end
	table.insert(glassSkins,fn)
	fn()
end
local function glassRefresh()
	for _,fn in ipairs(glassSkins) do fn() end
end
local function markDots()
	for nm,st in pairs(dotStrokes) do
		st.Transparency=nm==currentTheme and 0 or 1
	end
end
local function setTheme(name)
	local th=themes[name]
	if not th then return end
	currentTheme=name
	T.Accent,T.AccentDark=th.Accent,th.AccentDark
	for _,fn in ipairs(skins) do fn() end
	markDots()
end
local function new(class,props,parent)
	local o=Instance.new(class)
	for k,v in pairs(props) do o[k]=v end
	o.Parent=parent
	return o
end
local function corner(o,r) return new("UICorner",{CornerRadius=UDim.new(0,r)},o) end
local function stroke(o,c,t)
	return new("UIStroke",{Color=c,Thickness=t or 1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},o)
end
local function tween(o,t,p,style,dir)
	if not FX.on then t=0 end
	local tw=TS:Create(o,TweenInfo.new(t,style or Enum.EasingStyle.Quad,dir or Enum.EasingDirection.Out),p)
	tw:Play()
	return tw
end
local function isPress(i)
	return i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1
end
local function isMove(i)
	return i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement
end
local conns={}
local function bind(signal,fn)
	local c=signal:Connect(fn)
	table.insert(conns,c)
	return c
end
local function press(btn,s)
	local sc=new("UIScale",{Scale=1},btn)
	btn.InputBegan:Connect(function(i)
		if isPress(i) then tween(sc,0.08,{Scale=s or 0.94}) end
	end)
	btn.InputEnded:Connect(function(i)
		if isPress(i) then tween(sc,0.2,{Scale=1},Enum.EasingStyle.Back) end
	end)
end
local function borderFx(st,host)
	local g=new("UIGradient",{},st)
	skin(function()
		local light=T.Accent:Lerp(Color3.new(1,1,1),0.6)
		g.Color=ColorSequence.new({
			ColorSequenceKeypoint.new(0,T.Accent),
			ColorSequenceKeypoint.new(0.5,light),
			ColorSequenceKeypoint.new(1,T.Accent),
		})
	end)
	table.insert(grads,{g=g,host=host})
end
bind(RS.Heartbeat,function(dt)
	if FX.border then
		for _,e in ipairs(grads) do
			if e.host.Visible then e.g.Rotation=(e.g.Rotation+dt*90)%360 end
		end
	end
end)

local gui=new("ScreenGui",{
	Name="RidKidHub",
	ResetOnSpawn=false,
	ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
	DisplayOrder=100,
},playerGui)

local function closeAll()
	for _,c in ipairs(conns) do c:Disconnect() end
	table.clear(conns)
	pcall(Sp.Destroy)
	pcall(Engine.Destroy)
	for _,c in ipairs(Tracked) do c:Disconnect() end
	table.clear(Tracked)
	_G.RidKidHubShutdown=nil
	gui:Destroy()
end
_G.RidKidHubShutdown=closeAll

local W,H=540,330
local BODY_Y,BODY_H=64,H-72

local root=new("Frame",{
	Size=UDim2.fromOffset(W,H),
	AnchorPoint=Vector2.new(0.5,0.5),
	Position=UDim2.fromScale(0.5,0.5),
	BackgroundTransparency=1,
},gui)
local userScale=new("UIScale",{Scale=1},root)
local main=new("Frame",{
	Size=UDim2.fromScale(1,1),
	AnchorPoint=Vector2.new(0.5,0.5),
	Position=UDim2.fromScale(0.5,0.5),
	BackgroundColor3=T.Bg,
	ClipsDescendants=true,
},root)
local animScale=new("UIScale",{Scale=0.7},main)
corner(main,16)
glass(main,0)
borderFx(stroke(main,Color3.new(1,1,1),2),root)

local function ripple(obj,i)
	local s=userScale.Scale
	local x=(i.Position.X-obj.AbsolutePosition.X)/s
	local y=(i.Position.Y-obj.AbsolutePosition.Y)/s
	local r=new("Frame",{
		Size=UDim2.fromOffset(0,0),
		AnchorPoint=Vector2.new(0.5,0.5),
		Position=UDim2.fromOffset(x,y),
		BackgroundColor3=Color3.new(1,1,1),
		BackgroundTransparency=0.8,
		BorderSizePixel=0,
		ZIndex=2,
	},obj)
	corner(r,200)
	local d=math.max(obj.AbsoluteSize.X,obj.AbsoluteSize.Y)*2.4/s
	tween(r,0.5,{Size=UDim2.fromOffset(d,d),BackgroundTransparency=1})
	task.delay(0.55,function() r:Destroy() end)
end

local function drag(handle,target,onTap)
	local active,start,orig,moved=false,nil,nil,false
	handle.InputBegan:Connect(function(i)
		if isPress(i) then
			active,start,orig,moved=true,i.Position,target.Position,false
			i.Changed:Connect(function()
				if i.UserInputState==Enum.UserInputState.End then
					active=false
					if onTap and not moved then onTap() end
				end
			end)
		end
	end)
	bind(UIS.InputChanged,function(i)
		if active and isMove(i) then
			local d=i.Position-start
			if d.Magnitude>6 then moved=true end
			target.Position=UDim2.new(orig.X.Scale,orig.X.Offset+d.X,orig.Y.Scale,orig.Y.Offset+d.Y)
		end
	end)
end

local shine=new("Frame",{
	Size=UDim2.new(0,70,1.6,0),
	AnchorPoint=Vector2.new(0.5,0.5),
	Position=UDim2.new(0,-80,0.5,0),
	Rotation=18,
	BackgroundColor3=Color3.new(1,1,1),
	BackgroundTransparency=0.92,
	BorderSizePixel=0,
	ZIndex=50,
},main)
new("UIGradient",{
	Transparency=NumberSequence.new({
		NumberSequenceKeypoint.new(0,1),
		NumberSequenceKeypoint.new(0.5,0),
		NumberSequenceKeypoint.new(1,1),
	}),
},shine)
task.spawn(function()
	while gui.Parent do
		task.wait(6)
		if gui.Parent and FX.on and FX.shine and root.Visible then
			shine.Position=UDim2.new(0,-80,0.5,0)
			local tw=tween(shine,1.3,{Position=UDim2.new(1,80,0.5,0)},Enum.EasingStyle.Sine,Enum.EasingDirection.InOut)
			tw.Completed:Wait()
		end
	end
end)

local header=new("Frame",{
	Size=UDim2.new(1,-16,0,48),
	Position=UDim2.fromOffset(8,8),
	BackgroundColor3=Color3.new(1,1,1),
},main)
corner(header,10)
stroke(header,T.Line)
glass(header,0.15)
local hg=new("UIGradient",{Rotation=0},header)
skin(function()
	hg.Color=ColorSequence.new(T.AccentDark:Lerp(T.Panel,0.35),T.Panel)
end)
drag(header,root)

local logo=new("TextLabel",{
	Size=UDim2.fromOffset(34,34),
	Position=UDim2.fromOffset(10,7),
	Text="R",
	Font=Enum.Font.GothamBlack,
	TextSize=19,
	TextColor3=T.Bg,
},header)
corner(logo,17)
paint(logo,"BackgroundColor3","Accent")
local logoScale=new("UIScale",{Scale=1},logo)
TS:Create(logoScale,TweenInfo.new(1.2,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Scale=1.08}):Play()

new("TextLabel",{
	Size=UDim2.new(1,-250,0,22),
	Position=UDim2.fromOffset(54,6),
	BackgroundTransparency=1,
	Text="RIDKID HUB",
	Font=Enum.Font.GothamBlack,
	TextSize=17,
	TextColor3=T.Text,
	TextXAlignment=Enum.TextXAlignment.Left,
},header)
local sub=new("TextLabel",{
	Size=UDim2.new(1,-250,0,14),
	Position=UDim2.fromOffset(54,28),
	BackgroundTransparency=1,
	Text="// SPIDER EDITION",
	Font=Enum.Font.GothamMedium,
	TextSize=12,
	TextXAlignment=Enum.TextXAlignment.Left,
},header)
paint(sub,"TextColor3","Accent")

for idx,nm in ipairs({"Gold","Red","Blue"}) do
	local d=new("TextButton",{
		Size=UDim2.fromOffset(16,16),
		Position=UDim2.new(1,-196+(idx-1)*22,0.5,-8),
		BackgroundColor3=themes[nm].Accent,
		Text="",
		AutoButtonColor=false,
	},header)
	corner(d,8)
	dotStrokes[nm]=stroke(d,Color3.new(1,1,1),2)
	press(d,0.8)
	d.Activated:Connect(function() setTheme(nm) end)
end
markDots()

local function iconButton(x,color)
	local b=new("TextButton",{
		Size=UDim2.fromOffset(32,32),
		Position=UDim2.new(1,x,0.5,-16),
		BackgroundColor3=color,
		Text="",
		AutoButtonColor=false,
	},header)
	corner(b,8)
	press(b,0.88)
	return b
end
local minBtn=iconButton(-82,T.AccentDark)
paint(minBtn,"BackgroundColor3","AccentDark")
paint(stroke(minBtn,T.Accent,1),"Color","Accent")
new("Frame",{
	Size=UDim2.fromOffset(12,2),
	AnchorPoint=Vector2.new(0.5,0.5),
	Position=UDim2.fromScale(0.5,0.5),
	BackgroundColor3=T.Text,
	BorderSizePixel=0,
},minBtn)
local closeBtn=iconButton(-42,T.Red)
for _,rot in ipairs({45,-45}) do
	new("Frame",{
		Size=UDim2.fromOffset(16,2),
		AnchorPoint=Vector2.new(0.5,0.5),
		Position=UDim2.fromScale(0.5,0.5),
		Rotation=rot,
		BackgroundColor3=Color3.new(1,1,1),
		BorderSizePixel=0,
	},closeBtn)
end
local searchHolder=new("Frame",{
	Size=UDim2.fromOffset(128,30),
	Position=UDim2.fromOffset(8,BODY_Y),
	BackgroundColor3=T.Panel,
},main)
corner(searchHolder,8)
glass(searchHolder,0.2)
local sStroke=stroke(searchHolder,T.Line)
local sRing=new("Frame",{
	Size=UDim2.fromOffset(10,10),
	Position=UDim2.fromOffset(9,8),
	BackgroundTransparency=1,
},searchHolder)
corner(sRing,5)
paint(stroke(sRing,T.Accent,2),"Color","Accent")
local sHandle=new("Frame",{
	Size=UDim2.fromOffset(7,2),
	AnchorPoint=Vector2.new(0.5,0.5),
	Position=UDim2.fromOffset(20,20),
	Rotation=45,
	BorderSizePixel=0,
},searchHolder)
paint(sHandle,"BackgroundColor3","Accent")
local searchBox=new("TextBox",{
	Size=UDim2.new(1,-34,1,0),
	Position=UDim2.fromOffset(30,0),
	BackgroundTransparency=1,
	Text="",
	PlaceholderText="Tìm chức năng...",
	PlaceholderColor3=T.Sub,
	TextColor3=T.Text,
	Font=Enum.Font.GothamMedium,
	TextSize=12,
	TextXAlignment=Enum.TextXAlignment.Left,
	ClearTextOnFocus=false,
},searchHolder)
searchBox.Focused:Connect(function() tween(sStroke,0.15,{Color=T.Accent}) end)
searchBox.FocusLost:Connect(function() tween(sStroke,0.15,{Color=T.Line}) end)

local sidePanel=new("Frame",{
	Size=UDim2.fromOffset(128,BODY_H-36),
	Position=UDim2.fromOffset(8,BODY_Y+36),
	BackgroundColor3=T.Panel,
},main)
corner(sidePanel,12)
glass(sidePanel,0.25)
local spStroke=stroke(sidePanel,T.Accent,1.5)
spStroke.Transparency=0.25
paint(spStroke,"Color","Accent")
local side=new("ScrollingFrame",{
	Size=UDim2.new(1,-12,1,-12),
	Position=UDim2.fromOffset(6,6),
	BackgroundTransparency=1,
	BorderSizePixel=0,
	ScrollBarThickness=0,
	CanvasSize=UDim2.new(),
	AutomaticCanvasSize=Enum.AutomaticSize.Y,
},sidePanel)
new("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},side)

local contentPanel=new("Frame",{
	Size=UDim2.fromOffset(W-152,BODY_H),
	Position=UDim2.fromOffset(144,BODY_Y),
	BackgroundColor3=T.Panel,
},main)
corner(contentPanel,12)
glass(contentPanel,0.25)
local cpStroke=stroke(contentPanel,T.Accent,1.5)
cpStroke.Transparency=0.25
paint(cpStroke,"Color","Accent")
local pageHolder=new("Frame",{
	Size=UDim2.new(1,-16,1,-16),
	Position=UDim2.fromOffset(8,8),
	BackgroundTransparency=1,
	ClipsDescendants=true,
},contentPanel)
local noResult=new("TextLabel",{
	Size=UDim2.new(1,0,0,40),
	Position=UDim2.fromOffset(0,40),
	BackgroundTransparency=1,
	Text="Không tìm thấy kết quả",
	Font=Enum.Font.GothamMedium,
	TextSize=13,
	TextColor3=T.Sub,
	Visible=false,
},pageHolder)

local pages,current={},nil
local function paintTabs()
	for _,p in ipairs(pages) do
		local on=p==current
		tween(p.Tab,0.2,{BackgroundColor3=on and T.AccentDark or T.Item})
		tween(p.Label,0.2,{TextColor3=on and T.Accent or T.Text})
		tween(p.Bar,0.25,{Size=on and UDim2.fromOffset(3,16) or UDim2.fromOffset(3,0)},Enum.EasingStyle.Back)
	end
end
local function applyFilter()
	if not current then return end
	local q=searchBox.Text:lower()
	local any=false
	local shown={}
	for _,it in ipairs(current.Items) do
		local v=q=="" or it.Name:find(q,1,true)~=nil
		it.Frame.Visible=v
		if v then
			any=true
			if it.Card then shown[it.Card]=true end
		end
	end
	for _,c in ipairs(current.Cards) do
		c.Visible=q=="" or shown[c]==true
	end
	noResult.Visible=not any
end
local function selectPage(page)
	if current==page then return end
	for _,p in ipairs(pages) do p.Group.Visible=p==page end
	current=page
	paintTabs()
	applyFilter()
	page.Group.GroupTransparency=1
	page.Group.Position=UDim2.fromOffset(18,0)
	tween(page.Group,0.3,{GroupTransparency=0,Position=UDim2.fromOffset(0,0)})
end
bind(searchBox:GetPropertyChangedSignal("Text"),applyFilter)
skin(paintTabs)

local Methods={}
Methods.__index=Methods

function Methods:Section(text)
	local card=new("Frame",{
		Size=UDim2.new(1,0,0,0),
		AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundColor3=T.Panel,
	},self.Frame)
	corner(card,12)
	glass(card,0.2)
	local st=stroke(card,T.Accent,1.2)
	st.Transparency=0.45
	paint(st,"Color","Accent")
	new("UIListLayout",{
		SortOrder=Enum.SortOrder.LayoutOrder,
		HorizontalAlignment=Enum.HorizontalAlignment.Center,
	},card)
	new("TextLabel",{
		Size=UDim2.new(1,0,0,30),
		BackgroundTransparency=1,
		Text=text,
		Font=Enum.Font.GothamBold,
		TextSize=14,
		TextColor3=T.Text,
		LayoutOrder=1,
	},card)
	local line=new("Frame",{
		Size=UDim2.new(1,-24,0,2),
		BorderSizePixel=0,
		LayoutOrder=2,
	},card)
	paint(line,"BackgroundColor3","Accent")
	new("UIGradient",{
		Transparency=NumberSequence.new({
			NumberSequenceKeypoint.new(0,1),
			NumberSequenceKeypoint.new(0.5,0),
			NumberSequenceKeypoint.new(1,1),
		}),
	},line)
	local body=new("Frame",{
		Size=UDim2.new(1,0,0,0),
		AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundTransparency=1,
		LayoutOrder=3,
	},card)
	new("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},body)
	new("UIPadding",{
		PaddingTop=UDim.new(0,8),
		PaddingBottom=UDim.new(0,8),
		PaddingLeft=UDim.new(0,8),
		PaddingRight=UDim.new(0,8),
	},body)
	self.Body,self.Card,self.CardName=body,card,text:lower()
	table.insert(self.Cards,card)
end

function Methods:_item(name,h)
	local f=new("Frame",{
		Size=UDim2.new(1,0,0,h),
		BackgroundColor3=T.Item,
		ClipsDescendants=true,
	},self.Body or self.Frame)
	corner(f,10)
	glass(f,0.25)
	local st=stroke(f,T.Line)
	f.MouseEnter:Connect(function() tween(st,0.15,{Color=T.Accent}) end)
	f.MouseLeave:Connect(function() tween(st,0.15,{Color=T.Line}) end)
	table.insert(self.Items,{Frame=f,Name=name:lower().." "..(self.CardName or ""),Card=self.Card})
	return f
end

function Methods:_row(name,desc,rightW)
	local h=desc and 52 or 42
	local f=self:_item(name.." "..(desc or ""),h)
	local edge=new("Frame",{
		Size=UDim2.fromOffset(3,0),
		AnchorPoint=Vector2.new(0,0.5),
		Position=UDim2.new(0,0,0.5,0),
		BorderSizePixel=0,
	},f)
	paint(edge,"BackgroundColor3","Accent")
	new("TextLabel",{
		Size=UDim2.new(1,-(rightW+14),0,desc and 20 or h),
		Position=UDim2.fromOffset(14,desc and 8 or 0),
		BackgroundTransparency=1,
		Text=name,
		Font=Enum.Font.GothamMedium,
		TextSize=14,
		TextColor3=T.Text,
		TextXAlignment=Enum.TextXAlignment.Left,
		TextTruncate=Enum.TextTruncate.AtEnd,
	},f)
	if desc then
		new("TextLabel",{
			Size=UDim2.new(1,-(rightW+14),0,16),
			Position=UDim2.fromOffset(14,28),
			BackgroundTransparency=1,
			Text=desc,
			Font=Enum.Font.Gotham,
			TextSize=11,
			TextColor3=T.Sub,
			TextXAlignment=Enum.TextXAlignment.Left,
			TextTruncate=Enum.TextTruncate.AtEnd,
		},f)
	end
	return f,h,edge
end

function Methods:Info(title,text)
	local f=self:_item(title,52)
	new("TextLabel",{
		Size=UDim2.new(1,-28,0,20),
		Position=UDim2.fromOffset(14,8),
		BackgroundTransparency=1,
		Text=title,
		Font=Enum.Font.GothamMedium,
		TextSize=14,
		TextColor3=T.Text,
		TextXAlignment=Enum.TextXAlignment.Left,
		TextTruncate=Enum.TextTruncate.AtEnd,
	},f)
	local body=new("TextLabel",{
		Size=UDim2.new(1,-28,0,16),
		Position=UDim2.fromOffset(14,28),
		BackgroundTransparency=1,
		Text=text,
		Font=Enum.Font.Gotham,
		TextSize=12,
		TextColor3=T.Sub,
		TextXAlignment=Enum.TextXAlignment.Left,
		TextTruncate=Enum.TextTruncate.AtEnd,
	},f)
	return function(t) body.Text=t end
end

function Methods:Toggle(name,default,callback,desc)
	local f,h,edge=self:_row(name,desc,64)
	local sw=new("Frame",{
		Size=UDim2.fromOffset(44,22),
		AnchorPoint=Vector2.new(1,0.5),
		Position=UDim2.new(1,-12,0.5,0),
		BackgroundColor3=T.Off,
	},f)
	corner(sw,11)
	local sst=stroke(sw,T.Accent,1)
	sst.Transparency=0.55
	paint(sst,"Color","Accent")
	local knob=new("Frame",{
		Size=UDim2.fromOffset(16,16),
		Position=UDim2.fromOffset(3,3),
		BackgroundColor3=Color3.new(1,1,1),
	},sw)
	corner(knob,8)
	local state=default and true or false
	local function render()
		tween(sw,0.2,{BackgroundColor3=state and T.Accent or T.Off})
		tween(knob,0.25,{Position=state and UDim2.fromOffset(25,3) or UDim2.fromOffset(3,3)},Enum.EasingStyle.Back)
		tween(edge,0.25,{Size=state and UDim2.fromOffset(3,h-16) or UDim2.fromOffset(3,0)},Enum.EasingStyle.Back)
	end
	skin(render)
	local function setState(v,silent)
		state=v and true or false
		render()
		if callback and not silent then callback(state) end
	end
	local hit=new("TextButton",{
		Size=UDim2.fromScale(1,1),
		BackgroundTransparency=1,
		Text="",
		ZIndex=3,
	},f)
	hit.InputBegan:Connect(function(i)
		if isPress(i) then ripple(f,i) end
	end)
	hit.Activated:Connect(function() setState(not state) end)
	return setState
end

function Methods:Button(name,callback)
	local f=self:_item(name,44)
	local b=new("TextButton",{
		Size=UDim2.new(1,-20,0,28),
		Position=UDim2.fromOffset(10,8),
		Text=name,
		Font=Enum.Font.GothamBold,
		TextSize=13,
		AutoButtonColor=false,
		ClipsDescendants=true,
	},f)
	corner(b,8)
	paint(b,"BackgroundColor3","AccentDark")
	paint(b,"TextColor3","Accent")
	paint(stroke(b,T.Accent,1),"Color","Accent")
	press(b,0.96)
	b.InputBegan:Connect(function(i)
		if isPress(i) then ripple(b,i) end
	end)
	b.Activated:Connect(function()
		if callback then callback() end
	end)
end

function Methods:Link(name,desc,link)
	local f=self:_row(name,desc,96)
	local b=new("TextButton",{
		Size=UDim2.fromOffset(78,28),
		AnchorPoint=Vector2.new(1,0.5),
		Position=UDim2.new(1,-12,0.5,0),
		Text="Chép",
		Font=Enum.Font.GothamBold,
		TextSize=13,
		TextColor3=T.Bg,
		AutoButtonColor=false,
		ClipsDescendants=true,
	},f)
	corner(b,8)
	paint(b,"BackgroundColor3","Accent")
	press(b,0.92)
	b.InputBegan:Connect(function(i)
		if isPress(i) then ripple(b,i) end
	end)
	b.Activated:Connect(function()
		local fn=setclipboard or toclipboard
		local ok=false
		if fn then ok=pcall(fn,link) end
		b.Text=ok and "Đã chép" or "Lỗi"
		task.delay(1.5,function()
			if b.Parent then b.Text="Chép" end
		end)
	end)
end

function Methods:Slider(name,min,max,default,callback,unit,desc)
	local h=desc and 66 or 54
	local f=self:_item(name.." "..(desc or ""),h)
	new("TextLabel",{
		Size=UDim2.new(1,-100,0,20),
		Position=UDim2.fromOffset(14,8),
		BackgroundTransparency=1,
		Text=name,
		Font=Enum.Font.GothamMedium,
		TextSize=14,
		TextColor3=T.Text,
		TextXAlignment=Enum.TextXAlignment.Left,
		TextTruncate=Enum.TextTruncate.AtEnd,
	},f)
	if desc then
		new("TextLabel",{
			Size=UDim2.new(1,-28,0,16),
			Position=UDim2.fromOffset(14,27),
			BackgroundTransparency=1,
			Text=desc,
			Font=Enum.Font.Gotham,
			TextSize=11,
			TextColor3=T.Sub,
			TextXAlignment=Enum.TextXAlignment.Left,
			TextTruncate=Enum.TextTruncate.AtEnd,
		},f)
	end
	local val=new("TextLabel",{
		Size=UDim2.fromOffset(80,20),
		Position=UDim2.new(1,-92,0,8),
		BackgroundTransparency=1,
		Text=tostring(default)..(unit or ""),
		Font=Enum.Font.GothamBold,
		TextSize=14,
		TextXAlignment=Enum.TextXAlignment.Right,
	},f)
	paint(val,"TextColor3","Accent")
	local track=new("Frame",{
		Size=UDim2.new(1,-32,0,8),
		Position=UDim2.fromOffset(16,h-18),
		BackgroundColor3=T.Off,
	},f)
	corner(track,4)
	local fill=new("Frame",{Size=UDim2.fromScale(0,1)},track)
	corner(fill,4)
	paint(fill,"BackgroundColor3","Accent")
	local knob=new("Frame",{
		Size=UDim2.fromOffset(18,18),
		AnchorPoint=Vector2.new(0.5,0.5),
		Position=UDim2.fromScale(0,0.5),
		BackgroundColor3=Color3.new(1,1,1),
	},track)
	corner(knob,9)
	paint(stroke(knob,T.Accent,2),"Color","Accent")
	local function set(a,silent)
		a=math.clamp(a,0,1)
		local v=math.floor(min+(max-min)*a+0.5)
		fill.Size=UDim2.fromScale(a,1)
		knob.Position=UDim2.fromScale(a,0.5)
		val.Text=tostring(v)..(unit or "")
		if callback and not silent then callback(v) end
	end
	set((default-min)/(max-min),true)
	local sliding=false
	local function fromX(x)
		set((x-track.AbsolutePosition.X)/track.AbsoluteSize.X)
	end
	local hit=new("TextButton",{
		Size=UDim2.new(1,0,0,34),
		Position=UDim2.fromOffset(0,h-34),
		BackgroundTransparency=1,
		Text="",
		ZIndex=5,
	},f)
	hit.InputBegan:Connect(function(i)
		if isPress(i) then
			sliding=true
			self.Frame.ScrollingEnabled=false
			tween(knob,0.12,{Size=UDim2.fromOffset(24,24)},Enum.EasingStyle.Back)
			fromX(i.Position.X)
		end
	end)
	bind(UIS.InputChanged,function(i)
		if sliding and isMove(i) then fromX(i.Position.X) end
	end)
	bind(UIS.InputEnded,function(i)
		if sliding and isPress(i) then
			sliding=false
			self.Frame.ScrollingEnabled=true
			tween(knob,0.15,{Size=UDim2.fromOffset(18,18)},Enum.EasingStyle.Back)
		end
	end)
	return function(v) set((v-min)/(max-min),true) end
end
local function icon(kind,parent)
	local box=new("Frame",{
		Size=UDim2.fromOffset(16,16),
		AnchorPoint=Vector2.new(0,0.5),
		Position=UDim2.new(0,12,0.5,0),
		BackgroundTransparency=1,
	},parent)
	local function fillPart(w,h2,x,y,r,rot)
		local p=new("Frame",{
			Size=UDim2.fromOffset(w,h2),
			AnchorPoint=Vector2.new(0.5,0.5),
			Position=UDim2.fromOffset(x,y),
			Rotation=rot or 0,
			BorderSizePixel=0,
		},box)
		corner(p,r or 1)
		paint(p,"BackgroundColor3","Accent")
	end
	local function ringPart(size,thick)
		local p=new("Frame",{
			Size=UDim2.fromOffset(size,size),
			AnchorPoint=Vector2.new(0.5,0.5),
			Position=UDim2.fromOffset(8,8),
			BackgroundTransparency=1,
		},box)
		corner(p,size)
		paint(stroke(p,T.Accent,thick),"Color","Accent")
	end
	if kind=="ring" then
		ringPart(14,2)
	elseif kind=="dotring" then
		ringPart(14,2)
		fillPart(4,4,8,8,2)
	elseif kind=="diamond" then
		fillPart(10,10,8,8,2,45)
	elseif kind=="square" then
		local p=new("Frame",{
			Size=UDim2.fromOffset(12,12),
			AnchorPoint=Vector2.new(0.5,0.5),
			Position=UDim2.fromOffset(8,8),
			BackgroundTransparency=1,
		},box)
		corner(p,3)
		paint(stroke(p,T.Accent,2),"Color","Accent")
	elseif kind=="bars" then
		fillPart(14,2,8,3)
		fillPart(10,2,6,8)
		fillPart(12,2,7,13)
	else
		fillPart(14,2,8,8)
		fillPart(2,14,8,8)
	end
end

local function Tab(name,kind)
	local btn=new("TextButton",{
		Size=UDim2.new(1,0,0,32),
		BackgroundColor3=T.Item,
		Text="",
		AutoButtonColor=false,
		ClipsDescendants=true,
	},side)
	corner(btn,9)
	glass(btn,0.15)
	stroke(btn,T.Line)
	press(btn,0.97)
	btn.InputBegan:Connect(function(i)
		if isPress(i) then ripple(btn,i) end
	end)
	icon(kind,btn)
	local label=new("TextLabel",{
		Size=UDim2.new(1,-40,1,0),
		Position=UDim2.fromOffset(36,0),
		BackgroundTransparency=1,
		Text=name,
		Font=Enum.Font.GothamBold,
		TextSize=13,
		TextColor3=T.Text,
		TextXAlignment=Enum.TextXAlignment.Left,
	},btn)
	local bar=new("Frame",{
		Size=UDim2.fromOffset(3,0),
		AnchorPoint=Vector2.new(0,0.5),
		Position=UDim2.new(0,3,0.5,0),
		BorderSizePixel=0,
	},btn)
	corner(bar,2)
	paint(bar,"BackgroundColor3","Accent")
	local group=new("CanvasGroup",{
		Size=UDim2.fromScale(1,1),
		BackgroundTransparency=1,
		Visible=false,
	},pageHolder)
	local frame=new("ScrollingFrame",{
		Size=UDim2.fromScale(1,1),
		BackgroundTransparency=1,
		BorderSizePixel=0,
		ScrollBarThickness=3,
		CanvasSize=UDim2.new(),
		AutomaticCanvasSize=Enum.AutomaticSize.Y,
	},group)
	paint(frame,"ScrollBarImageColor3","Accent")
	new("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},frame)
	new("UIPadding",{PaddingRight=UDim.new(0,6),PaddingBottom=UDim.new(0,4)},frame)
	local page=setmetatable({
		Name=name,Group=group,Frame=frame,Tab=btn,Label=label,Bar=bar,Items={},Cards={},
	},Methods)
	table.insert(pages,page)
	btn.Activated:Connect(function() selectPage(page) end)
	return page
end

local home=Tab("HOME","diamond")
local anim=Tab("ANIM","ring")
local skill=Tab("SKILL","dotring")
local aim=Tab("AIM","bars")
local authors=Tab("TÁC GIẢ","square")
local setting=Tab("SETTING","cross")

home:Section("Thông tin")
home:Info("Xin chào, "..player.DisplayName,"Tài khoản: @"..player.Name)
local setPerf=home:Info("Hiệu năng","FPS: --")
local acc,frames=0,0
bind(RS.Heartbeat,function(dt)
	if current~=home or not root.Visible then return end
	acc=acc+dt
	frames=frames+1
	if acc>=0.5 then
		setPerf("FPS: "..math.floor(frames/acc+0.5))
		acc,frames=0,0
	end
end)
home:Section("Phím tắt")
home:Info("Spider-Man","E vung · Q bắn · F đu tơ · Z bò tường · R dừng")
home:Info("Menu","RightShift để thu gọn hoặc mở lại")

local animSet={}
local function pickAnim(i,v)
	if v then
		animSet[3-i](false,true)
		Engine.Set(i)
	else
		Engine.Set(0)
	end
end
anim:Section("Animation Spider-Man")
animSet[1]=anim:Toggle("Spider-Man",false,function(v) pickAnim(1,v) end,"Animation 1")
animSet[2]=anim:Toggle("Custom",false,function(v) pickAnim(2,v) end,"Animation 2")
anim:Info("Lưu ý","Tự tạm dừng khi đang vung tơ, bắn tơ, bò tường")

skill:Section("Spider System")
skill:Toggle("Bật Spider System",S.Power,function(v)
	Sp.toggleSound(v)
	Sp.setPower(v)
end,"Công tắc tổng cho mọi kỹ năng")
skill:Toggle("Vung tơ [E]",S.Swing,function(v)
	Sp.toggleSound(v)
	Sp.setSkill("Swing",v)
end,"Đu theo đường tơ như con lắc")
skill:Toggle("Bắn tơ [Q]",S.Shoot,function(v)
	Sp.toggleSound(v)
	Sp.setSkill("Shoot",v)
end,"Bắn nhiều tơ và lơ lửng")
skill:Toggle("Bò tường [Z]",S.Crawl,function(v)
	Sp.toggleSound(v)
	Sp.setSkill("Crawl",v)
end,"Bám tường bằng bốn chi")
skill:Section("Tốc độ")
skill:Slider("Tốc độ vung tơ",1,670,Speed.Swing,function(v) Speed.Swing=v end,"","Tốc độ tối đa khi đu")
skill:Slider("Tốc độ lơ lửng",1,670,Speed.Shoot,function(v) Speed.Shoot=v end,"","Tốc độ bay khi bắn tơ")
skill:Section("Điều khiển")
skill:Info("Nút ĐU TƠ [F]","Chỉ hiện sau khi đã bắn tơ")
skill:Button("Dừng mọi kỹ năng [R]",function() Sp.stopAll() end)

aim:Section("Tâm ngắm")
local setMoveAim
setMoveAim=aim:Toggle("Di chuyển tâm",false,function(v)
	if UI.LockAim then
		setMoveAim(false,true)
		return
	end
	Sp.setAimEdit(v)
end,"Kéo tâm trên màn hình để đổi vị trí")
aim:Toggle("Khoá tâm",false,function(v)
	UI.LockAim=v
	if v then
		setMoveAim(false,true)
		Sp.setAimEdit(false)
	end
	Sp.refresh()
end,"Chặn kéo tâm và chỉnh X Y")
local setAimX,setAimY
setAimX=aim:Slider("Tâm ngắm X",5,95,math.floor(CFG.AimX*100+0.5),function(v)
	if UI.LockAim then
		Sp.onAim(CFG.AimX,CFG.AimY)
		return
	end
	Sp.setAim(v/100,CFG.AimY)
end,"%")
setAimY=aim:Slider("Tâm ngắm Y",5,95,math.floor(CFG.AimY*100+0.5),function(v)
	if UI.LockAim then
		Sp.onAim(CFG.AimX,CFG.AimY)
		return
	end
	Sp.setAim(CFG.AimX,v/100)
end,"%")
Sp.onAim=function(x,y)
	setAimX(math.floor(x*100+0.5))
	setAimY(math.floor(y*100+0.5))
end
aim:Slider("Kích thước tâm",50,200,100,function(v)
	UI.AimScale=v/100
	Sp.setAimScale(v/100)
end,"%")
aim:Section("Nút trên màn hình")
aim:Toggle("Khoá nút",false,function(v) UI.LockBtn=v end,"Chặn kéo nút SWING SHOOT ĐU TƠ WALL")
aim:Slider("Cỡ nút",50,200,100,function(v)
	UI.BtnScale=v/100
	Sp.resizeFloats()
end,"%")

authors:Section("Đội ngũ RidKid Hub")
authors:Link("Tác giả chính","tiktok.com/@hoclamscript_roblox","https://www.tiktok.com/@hoclamscript_roblox")
authors:Link("Người phụ trách làm","tiktok.com/@viet69xhamter","https://www.tiktok.com/@viet69xhamter")
authors:Link("Emi Fukada (thư ký tổng)","tiktok.com/@quocdaicofgi","https://www.tiktok.com/@quocdaicofgi")
authors:Section("Liên kết")
authors:Link("Discord","discord.gg/Pfrxphu6M","https://discord.gg/Pfrxphu6M")
authors:Link("Link bio","linkbio.co/hoclamscript92","https://linkbio.co/hoclamscript92")

local minimize
setting:Section("Giao diện")
setting:Slider("Độ trong suốt",0,70,20,function(v)
	Glass.main=v/100
	glassRefresh()
end,"%","Nền kính của menu")
setting:Slider("Kích thước menu",70,130,100,function(v)
	userScale.Scale=v/100
end,"%")
setting:Section("Hiệu ứng")
setting:Toggle("Hiệu ứng",true,function(v) FX.on=v end,"Bật hoặc tắt hoạt ảnh")
setting:Toggle("Viền chuyển động",true,function(v) FX.border=v end,"Viền sáng xoay quanh menu")
setting:Toggle("Ánh sáng quét",true,function(v) FX.shine=v end,"Vệt sáng lướt qua menu")
setting:Section("Menu")
setting:Button("Thu gọn menu",function() minimize() end)
setting:Button("Đóng menu",closeAll)

local bubble=new("TextButton",{
	Size=UDim2.fromOffset(56,56),
	AnchorPoint=Vector2.new(0.5,0.5),
	Position=root.Position,
	BackgroundColor3=T.Bg,
	BackgroundTransparency=0.1,
	Text="",
	AutoButtonColor=false,
	Visible=false,
},gui)
new("UICorner",{CornerRadius=UDim.new(0.5,0)},bubble)
local bubbleImg=new("ImageLabel",{
	Size=UDim2.fromScale(1,1),
	BackgroundTransparency=1,
	Image="rbxassetid://130920436247899",
	ScaleType=Enum.ScaleType.Crop,
},bubble)
new("UICorner",{CornerRadius=UDim.new(0.5,0)},bubbleImg)
borderFx(stroke(bubble,Color3.new(1,1,1),2.5),bubble)
local bubbleScale=new("UIScale",{Scale=1},bubble)
local minimized=false
local function restore()
	if not minimized then return end
	minimized=false
	root.Position=UDim2.fromScale(0.5,0.5)
	bubble.Visible=false
	root.Visible=true
	animScale.Scale=0.2
	tween(animScale,0.35,{Scale=1},Enum.EasingStyle.Back)
end
minimize=function()
	if minimized then return end
	minimized=true
	bubble.Position=root.Position
	local tw=tween(animScale,0.22,{Scale=0.01},Enum.EasingStyle.Back,Enum.EasingDirection.In)
	tw.Completed:Connect(function()
		if minimized then
			root.Visible=false
			bubble.Visible=true
			bubbleScale.Scale=0.01
			tween(bubbleScale,0.3,{Scale=1},Enum.EasingStyle.Back)
		end
	end)
end
drag(bubble,bubble,restore)
minBtn.Activated:Connect(minimize)
closeBtn.Activated:Connect(closeAll)
bind(UIS.InputBegan,function(i,gp)
	if gp then return end
	if i.KeyCode==Enum.KeyCode.RightShift then
		if minimized then restore() else minimize() end
	end
end)

selectPage(home)
tween(animScale,0.5,{Scale=1},Enum.EasingStyle.Back)
end
