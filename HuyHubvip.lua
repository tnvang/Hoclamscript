local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")

local player=Players.LocalPlayer
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

local function getJoint(part,name)
	local p=char and char:WaitForChild(part,5)
	local m=p and p:WaitForChild(name,5)
	if m and m:IsA("Motor6D") then
		local base=m.C0
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
	if animate and animate.Parent then animate.Disabled=false end
end

local function update(dt)
	if not engaged or not rig or not hum or hum.Health<=0 or not rootPart or not rootPart.Parent then return end
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

if player.Character then task.spawn(setup,player.Character) end
player.CharacterAdded:Connect(function(ch) task.spawn(setup,ch) end)
player.CharacterRemoving:Connect(teardown)
local UserInputService=game:GetService("UserInputService")
local playerGui=player:WaitForChild("PlayerGui")

for _,n in ipairs({"HuyPremium","AnimationHub"}) do
	local old=playerGui:FindFirstChild(n)
	if old then old:Destroy() end
end

local function new(class,props,parent)
	local o=Instance.new(class)
	for k,v in pairs(props) do o[k]=v end
	o.Parent=parent
	return o
end

local function tween(o,t,props,style,dir)
	local tw=TweenService:Create(o,TweenInfo.new(t,style or Enum.EasingStyle.Quint,dir or Enum.EasingDirection.Out),props)
	tw:Play()
	return tw
end

local C={
	bg0=Color3.fromRGB(13,14,23),
	bg1=Color3.fromRGB(24,21,42),
	card=Color3.fromRGB(28,30,47),
	cardHover=Color3.fromRGB(36,39,60),
	off=Color3.fromRGB(58,62,86),
	white=Color3.fromRGB(246,247,253),
	sub=Color3.fromRGB(140,146,176),
	line=Color3.fromRGB(52,56,82),
	red=Color3.fromRGB(240,64,84),
	orange=Color3.fromRGB(255,146,72),
	blue=Color3.fromRGB(72,148,255),
	cyan=Color3.fromRGB(94,226,255),
	violet=Color3.fromRGB(150,96,255),
}

local BRAND=ColorSequence.new({
	ColorSequenceKeypoint.new(0,C.red),
	ColorSequenceKeypoint.new(0.5,C.violet),
	ColorSequenceKeypoint.new(1,C.blue),
})

local spinners={}
local cons={}

local function spin(g)
	spinners[#spinners+1]=g
	return g
end

local function round(parent,r)
	return new("UICorner",{CornerRadius=r},parent)
end

local gui=new("ScreenGui",{Name="HuyPremium",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=100,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},playerGui)

local PW,PH=272,212
local BS=56

local panel=new("CanvasGroup",{Name="Panel",Size=UDim2.fromOffset(PW,PH),Position=UDim2.fromOffset(18,110),BackgroundColor3=C.bg0,BorderSizePixel=0},gui)
round(panel,UDim.new(0,18))
local panelScale=new("UIScale",{Scale=1},panel)
local pstroke=new("UIStroke",{Thickness=1.5,Color=C.white,Transparency=0.1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},panel)
spin(new("UIGradient",{Color=BRAND},pstroke))

local bgFrame=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=C.white,BorderSizePixel=0},panel)
new("UIGradient",{Color=ColorSequence.new(C.bg1,C.bg0),Rotation=90},bgFrame)

local header=new("Frame",{Size=UDim2.new(1,0,0,46),BackgroundTransparency=1},panel)

local logo=new("Frame",{Size=UDim2.fromOffset(30,30),Position=UDim2.fromOffset(12,8),BackgroundColor3=C.white,BorderSizePixel=0},header)
round(logo,UDim.new(0,9))
new("UIGradient",{Color=BRAND,Rotation=45},logo)
new("TextLabel",{Text="H",Font=Enum.Font.GothamBlack,TextSize=16,TextColor3=C.white,BackgroundTransparency=1,Size=UDim2.fromScale(1,1)},logo)

local title=new("TextLabel",{Text="HUY PREMIUM",Font=Enum.Font.GothamBlack,TextSize=14,TextColor3=C.white,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,Position=UDim2.fromOffset(50,6),Size=UDim2.new(1,-136,0,20)},header)
new("UIGradient",{Color=ColorSequence.new(C.white,Color3.fromRGB(196,176,255))},title)
new("TextLabel",{Text="Animation Suite",Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.sub,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,Position=UDim2.fromOffset(50,24),Size=UDim2.new(1,-136,0,14)},header)

local function headerButton(x,hover)
	local b=new("TextButton",{Text="",AutoButtonColor=false,BackgroundColor3=C.card,BorderSizePixel=0,Size=UDim2.fromOffset(26,26),Position=UDim2.new(1,x,0.5,-13)},header)
	round(b,UDim.new(0,8))
	b.MouseEnter:Connect(function() tween(b,0.15,{BackgroundColor3=hover}) end)
	b.MouseLeave:Connect(function() tween(b,0.15,{BackgroundColor3=C.card}) end)
	return b
end

local function stroke2(parent,rot)
	local f=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(11,2),BackgroundColor3=C.white,BorderSizePixel=0,Rotation=rot},parent)
	round(f,UDim.new(1,0))
end

local minBtn=headerButton(-68,C.off)
local closeBtn=headerButton(-36,C.red)
stroke2(minBtn,0)
stroke2(closeBtn,45)
stroke2(closeBtn,-45)

local dragZone=new("TextButton",{Text="",BackgroundTransparency=1,AutoButtonColor=false,Size=UDim2.new(1,-84,1,0)},header)

local accent=new("Frame",{Size=UDim2.new(1,-24,0,2),Position=UDim2.fromOffset(12,46),BackgroundColor3=C.white,BorderSizePixel=0},panel)
round(accent,UDim.new(1,0))
new("UIGradient",{Color=BRAND},accent)

local function makeCard(y,num,name,sub,c1,c2)
	local card=new("TextButton",{Text="",AutoButtonColor=false,BackgroundColor3=C.card,BorderSizePixel=0,Size=UDim2.new(1,-24,0,54),Position=UDim2.fromOffset(12,y)},panel)
	round(card,UDim.new(0,13))
	local stroke=new("UIStroke",{Color=C.line,Thickness=1.2,Transparency=0.4,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},card)
	local icon=new("Frame",{Size=UDim2.fromOffset(34,34),Position=UDim2.fromOffset(10,10),BackgroundColor3=C.off,BorderSizePixel=0},card)
	round(icon,UDim.new(0,10))
	local glow=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=C.white,BackgroundTransparency=1,BorderSizePixel=0},icon)
	round(glow,UDim.new(0,10))
	new("UIGradient",{Color=ColorSequence.new(c1,c2),Rotation=45},glow)
	new("TextLabel",{Text=num,Font=Enum.Font.GothamBlack,TextSize=15,TextColor3=C.white,BackgroundTransparency=1,Size=UDim2.fromScale(1,1)},icon)
	new("TextLabel",{Text=name,Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.white,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,Position=UDim2.fromOffset(54,9),Size=UDim2.fromOffset(136,18)},card)
	local subLbl=new("TextLabel",{Text=sub,Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.sub,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,Position=UDim2.fromOffset(54,28),Size=UDim2.fromOffset(136,14)},card)
	local pill=new("Frame",{Size=UDim2.fromOffset(44,22),Position=UDim2.new(1,-54,0.5,-11),BackgroundColor3=C.off,BorderSizePixel=0},card)
	round(pill,UDim.new(1,0))
	local stateLbl=new("TextLabel",{Text="OFF",Font=Enum.Font.GothamBold,TextSize=9,TextColor3=C.white,BackgroundTransparency=1,Size=UDim2.new(0,22,1,0),Position=UDim2.fromOffset(19,0)},pill)
	local knob=new("Frame",{Size=UDim2.fromOffset(16,16),Position=UDim2.fromOffset(3,3),BackgroundColor3=C.white,BorderSizePixel=0},pill)
	round(knob,UDim.new(1,0))
	card.MouseEnter:Connect(function() tween(card,0.15,{BackgroundColor3=C.cardHover}) end)
	card.MouseLeave:Connect(function() tween(card,0.15,{BackgroundColor3=C.card}) end)
	local state=false
	local obj={Button=card}
	function obj.Get() return state end
	function obj.Set(v,animated)
		state=v
		local t=animated and 0.25 or 0
		tween(stroke,t,{Color=v and c1 or C.line,Transparency=v and 0.1 or 0.4})
		tween(glow,t,{BackgroundTransparency=v and 0 or 1})
		tween(pill,t,{BackgroundColor3=v and c1 or C.off})
		tween(knob,t,{Position=v and UDim2.fromOffset(25,3) or UDim2.fromOffset(3,3)})
		tween(stateLbl,t,{Position=v and UDim2.fromOffset(4,0) or UDim2.fromOffset(19,0)})
		tween(subLbl,t,{TextColor3=v and c1 or C.sub})
		stateLbl.Text=v and "ON" or "OFF"
	end
	return obj
end

local ACC={{C.red,C.orange},{C.blue,C.cyan}}
local cards={
	makeCard(58,"1","Animation Huy hub 1","Spider-Man Movement",C.red,C.orange),
	makeCard(120,"2","Animation Huy hub 2","Custom Movement",C.blue,C.cyan),
}

local footer=new("Frame",{Size=UDim2.new(1,-24,0,22),Position=UDim2.fromOffset(12,PH-28),BackgroundTransparency=1},panel)
local sdot=new("Frame",{Size=UDim2.fromOffset(7,7),Position=UDim2.fromOffset(3,7),BackgroundColor3=C.off,BorderSizePixel=0},footer)
round(sdot,UDim.new(1,0))
local stext=new("TextLabel",{Text="Chưa bật animation",Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.sub,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,Position=UDim2.fromOffset(17,0),Size=UDim2.new(1,-17,1,0)},footer)

local badge=new("TextButton",{Name="Badge",Text="",AutoButtonColor=false,BackgroundTransparency=1,Size=UDim2.fromOffset(BS,BS),Position=UDim2.fromOffset(18,110),Visible=false},gui)
local badgeScale=new("UIScale",{Scale=1},badge)
local fill=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=C.white,BorderSizePixel=0},badge)
round(fill,UDim.new(1,0))
new("UIGradient",{Color=ColorSequence.new(Color3.fromRGB(38,29,70),Color3.fromRGB(13,14,24)),Rotation=90},fill)
local bstroke=new("UIStroke",{Thickness=2,Color=C.white,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},fill)
spin(new("UIGradient",{Color=BRAND},bstroke))
local btext=new("TextLabel",{Text="HUY",Font=Enum.Font.GothamBlack,TextSize=16,TextColor3=C.white,BackgroundTransparency=1,Size=UDim2.fromScale(1,1)},badge)
new("UIGradient",{Color=ColorSequence.new(C.white,Color3.fromRGB(196,176,255)),Rotation=90},btext)
local badgeDot=new("Frame",{Size=UDim2.fromOffset(14,14),Position=UDim2.new(1,-14,0,0),BackgroundColor3=C.off,BorderSizePixel=0,Visible=false},badge)
round(badgeDot,UDim.new(1,0))
new("UIStroke",{Color=C.bg0,Thickness=2},badgeDot)

local function clampPos(pos,size)
	local s=gui.AbsoluteSize
	return Vector2.new(clamp(pos.X,0,max(0,s.X-size.X)),clamp(pos.Y,0,max(0,s.Y-size.Y)))
end

local collapsed=false
local token=0

local function setCollapsed(v)
	if v==collapsed then return end
	collapsed=v
	token+=1
	local my=token
	if v then
		local p=clampPos(panel.AbsolutePosition,Vector2.new(BS,BS))
		badge.Position=UDim2.fromOffset(p.X,p.Y)
		tween(panel,0.22,{GroupTransparency=1},Enum.EasingStyle.Quad)
		tween(panelScale,0.22,{Scale=0.7},Enum.EasingStyle.Quad)
		task.delay(0.22,function()
			if token==my then panel.Visible=false end
		end)
		badgeScale.Scale=0.4
		badge.Visible=true
		tween(badgeScale,0.38,{Scale=1},Enum.EasingStyle.Back)
	else
		local p=clampPos(badge.AbsolutePosition,Vector2.new(PW,PH))
		panel.Position=UDim2.fromOffset(p.X,p.Y)
		panelScale.Scale=0.7
		panel.GroupTransparency=1
		panel.Visible=true
		tween(panel,0.3,{GroupTransparency=0},Enum.EasingStyle.Quad)
		tween(panelScale,0.38,{Scale=1},Enum.EasingStyle.Back)
		tween(badgeScale,0.18,{Scale=0.4},Enum.EasingStyle.Quad)
		task.delay(0.18,function()
			if token==my then badge.Visible=false end
		end)
	end
end

local function makeDraggable(handle,target,size,onTap)
	local active=false
	local moved=0
	local startInput,startPos
	handle.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
			active=true
			moved=0
			startInput=input.Position
			startPos=target.AbsolutePosition
			input.Changed:Connect(function()
				if input.UserInputState==Enum.UserInputState.End then
					if active and onTap and moved<8 then onTap() end
					active=false
				end
			end)
		end
	end)
	cons[#cons+1]=UserInputService.InputChanged:Connect(function(input)
		if not active then return end
		if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then
			local d=input.Position-startInput
			moved=max(moved,d.Magnitude)
			local p=clampPos(startPos+Vector2.new(d.X,d.Y),size)
			target.Position=UDim2.fromOffset(p.X,p.Y)
		end
	end)
end

makeDraggable(dragZone,panel,Vector2.new(PW,PH))
makeDraggable(badge,badge,Vector2.new(BS,BS),function() setCollapsed(false) end)

local function refresh()
	local idx=cards[1].Get() and 1 or (cards[2].Get() and 2 or 0)
	Engine.Set(idx)
	local acc=idx>0 and ACC[idx][1] or C.off
	tween(sdot,0.25,{BackgroundColor3=acc})
	tween(badgeDot,0.25,{BackgroundColor3=acc})
	badgeDot.Visible=idx>0
	stext.Text=idx>0 and ("Đang chạy · Animation Huy hub "..idx) or "Chưa bật animation"
end

local function choose(i)
	local want=not cards[i].Get()
	cards[i].Set(want,true)
	if want then cards[3-i].Set(false,true) end
	refresh()
end

cards[1].Button.Activated:Connect(function() choose(1) end)
cards[2].Button.Activated:Connect(function() choose(2) end)
minBtn.Activated:Connect(function() setCollapsed(true) end)

closeBtn.Activated:Connect(function()
	tween(panel,0.22,{GroupTransparency=1},Enum.EasingStyle.Quad)
	tween(panelScale,0.22,{Scale=0.8},Enum.EasingStyle.Quad)
	task.delay(0.24,function()
		if gui.Parent then gui:Destroy() end
	end)
end)

local spinConn=RunService.Heartbeat:Connect(function(dt)
	for i=#spinners,1,-1 do
		local g=spinners[i]
		if g.Parent then
			g.Rotation=(g.Rotation+dt*70)%360
		else
			table.remove(spinners,i)
		end
	end
end)

gui.Destroying:Connect(function()
	spinConn:Disconnect()
	for _,cn in ipairs(cons) do cn:Disconnect() end
	Engine.Shutdown()
end)

panelScale.Scale=0.9
panel.GroupTransparency=1
tween(panel,0.5,{GroupTransparency=0})
tween(panelScale,0.5,{Scale=1},Enum.EasingStyle.Back)

local function typeText(label,delay)
	local n=utf8.len(label.Text) or #label.Text
	for i=1,n do
		if not label.Parent then return end
		label.MaxVisibleGraphemes=i
		task.wait(delay)
	end
	label.MaxVisibleGraphemes=-1
end

task.spawn(function()
	local card=new("CanvasGroup",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0.5,0,0.2,24),Size=UDim2.fromOffset(318,84),BackgroundColor3=Color3.fromRGB(15,16,27),BorderSizePixel=0,GroupTransparency=1},gui)
	round(card,UDim.new(0,16))
	local wstroke=new("UIStroke",{Thickness=1.5,Color=C.white,Transparency=0.1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},card)
	spin(new("UIGradient",{Color=BRAND},wstroke))
	local bar=new("Frame",{Size=UDim2.new(0,4,1,0),BackgroundColor3=C.white,BorderSizePixel=0},card)
	new("UIGradient",{Color=BRAND,Rotation=90},bar)
	local t1=new("TextLabel",{Text="Xin chào Huy!",Font=Enum.Font.GothamBlack,TextSize=22,TextColor3=C.white,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,Position=UDim2.fromOffset(20,10),Size=UDim2.new(1,-32,0,28),MaxVisibleGraphemes=0},card)
	new("UIGradient",{Color=ColorSequence.new(C.white,Color3.fromRGB(196,176,255))},t1)
	local t2=new("TextLabel",{Text="Chúc bạn một ngày tốt lành và may mắn nha",Font=Enum.Font.Gotham,TextSize=13,TextColor3=Color3.fromRGB(205,208,228),BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,TextWrapped=true,Position=UDim2.fromOffset(20,42),Size=UDim2.new(1,-32,0,34),MaxVisibleGraphemes=0},card)
	tween(card,0.6,{GroupTransparency=0,Position=UDim2.new(0.5,0,0.2,0)})
	task.wait(0.4)
	typeText(t1,0.045)
	task.wait(0.1)
	typeText(t2,0.024)
	task.wait(3)
	if not card.Parent then return end
	tween(card,0.6,{GroupTransparency=1,Position=UDim2.new(0.5,0,0.2,-16)},Enum.EasingStyle.Quad,Enum.EasingDirection.In)
	task.wait(0.65)
	card:Destroy()
end)
