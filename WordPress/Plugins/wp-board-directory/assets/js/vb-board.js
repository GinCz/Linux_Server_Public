/**
 * WP Board & Directory - Vanilla JS Core
 * Lightweight, zero dependencies (No jQuery required)
 */

document.addEventListener('DOMContentLoaded', function() {

    // 1. Voting & Ratings Handler (Likes & Dislikes)
    document.addEventListener('click', function(e) {
        var btn = e.target.closest('.vb-btn-vote');
        if (!btn) return;

        e.preventDefault();
        var targetType = btn.getAttribute('data-target') || 'listing';
        var targetId   = btn.getAttribute('data-id');
        var voteVal    = btn.getAttribute('data-vote');
        var likesSpan    = document.getElementById('vb-likes-' + targetId);
        var dislikesSpan = document.getElementById('vb-dislikes-' + targetId);

        if (!targetId || !voteVal) return;

        btn.disabled = true;

        var params = new URLSearchParams({
            action: 'vb_submit_vote',
            nonce: (window.vbBoardData && window.vbBoardData.nonce) ? window.vbBoardData.nonce : '',
            target_type: targetType,
            target_id: targetId,
            rating: voteVal
        });

        var ajaxUrl = (window.vbBoardData && window.vbBoardData.ajaxUrl) ? window.vbBoardData.ajaxUrl : '/wp-admin/admin-ajax.php';

        fetch(ajaxUrl, {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: params
        })
        .then(function(res) { return res.json(); })
        .then(function(data) {
            btn.disabled = false;
            if (data.success) {
                if (likesSpan && typeof data.data.likes !== 'undefined') {
                    likesSpan.textContent = data.data.likes;
                }
                if (dislikesSpan && typeof data.data.dislikes !== 'undefined') {
                    dislikesSpan.textContent = data.data.dislikes;
                }
                alert(data.data.message || 'Спасибо за оценку!');
            } else {
                alert(data.data ? data.data.message : 'Ошибка при сохранении оценки.');
            }
        })
        .catch(function(err) {
            btn.disabled = false;
            alert('Сетевая ошибка при отправке оценки.');
        });
    });

    // 2. Client-Side WebP Image Compressor (Up to 15 photos max 1024px)
    window.vbCompressImageToWebP = function(file, maxWidth, quality, callback) {
        maxWidth = maxWidth || 1024;
        quality  = quality || 0.8;

        var reader = new FileReader();
        reader.readAsDataURL(file);
        reader.onload = function(event) {
            var img = new Image();
            img.src = event.target.result;
            img.onload = function() {
                var elem = document.createElement('canvas');
                var width = img.width;
                var height = img.height;

                if (width > maxWidth) {
                    height = Math.round(height * (maxWidth / width));
                    width = maxWidth;
                }

                elem.width = width;
                elem.height = height;

                var ctx = elem.getContext('2d');
                ctx.drawImage(img, 0, 0, width, height);

                elem.toBlob(function(blob) {
                    callback(blob);
                }, 'image/webp', quality);
            };
        };
    };

    // 3. Dashboard Bulk Checkbox Selection (Select All / Deselect All)
    document.addEventListener('change', function(e) {
        if (e.target.classList.contains('vb-select-all-checkbox')) {
            var targetClass = e.target.getAttribute('data-target');
            var isChecked   = e.target.checked;
            if (targetClass) {
                var checkboxes = document.querySelectorAll('.' + targetClass);
                checkboxes.forEach(function(chk) {
                    chk.checked = isChecked;
                });
                var allToggles = document.querySelectorAll('.vb-select-all-checkbox[data-target="' + targetClass + '"]');
                allToggles.forEach(function(toggle) {
                    toggle.checked = isChecked;
                });
            }
        }
    });

    // 4. Dashboard Bulk Form Validation & Action Confirmation
    window.vbValidateBulk = function(form) {
        var checkboxes = form.querySelectorAll('input[name="item_ids[]"]:checked');
        if (checkboxes.length === 0) {
            alert('Пожалуйста, отметьте галочками хотя бы один элемент.');
            return false;
        }
        var op = form.bulk_op ? form.bulk_op.value : '';
        if (!op) {
            alert('Пожалуйста, выберите действие из списка.');
            return false;
        }
        if (op === 'delete') {
            return confirm('Вы действительно хотите удалить выбранные элементы (' + checkboxes.length + ' шт.)?');
        }
        if (op.indexOf('renew') === 0) {
            return confirm('Продлить выбранные публикации (' + checkboxes.length + ' шт.)?');
        }
        return true;
    };
});
