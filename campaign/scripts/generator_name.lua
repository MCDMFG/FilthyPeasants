--
-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.
--

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	if linktarget then
		window[linktarget[1]].activate();
	end
	return true;
end

function onDragStart(button, x, y, draginfo)
	if linktarget and window[linktarget[1]].onDragStart then
		window[linktarget[1]].onDragStart(button, x, y, draginfo);
		return true;
	end
end

function onDrop(x, y, draginfo)
	if linktarget and window[linktarget[1]].onDrop then
		return window[linktarget[1]].onDrop(x, y, draginfo);
	end
end