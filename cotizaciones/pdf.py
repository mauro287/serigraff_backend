from io import BytesIO
from xml.sax.saxutils import escape
from decimal import Decimal
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle


def generar_pdf(c):
    stream = BytesIO()
    styles = getSampleStyleSheet()
    styles['Normal'].leading = 15
    def p(text, style='Normal'):
        return Paragraph(escape(str(text)).replace('\n', '<br/>'), styles[style])
    doc = SimpleDocTemplate(stream, pagesize=A4, rightMargin=2*cm, leftMargin=2*cm,
                            topMargin=2*cm, bottomMargin=2*cm, title=f'Cotización {c.pk} - Serigraff')
    total = f'USD {c.total_estimado:.2f}' if c.total_estimado is not None else 'Pendiente de valoración'
    unitario = f'USD {(c.total_estimado / c.cantidad).quantize(Decimal("0.01")):.2f}' if c.total_estimado is not None and c.cantidad else '-'
    story = [p('SERIGRAFF', 'Title'), p(f'COTIZACIÓN #{c.pk}', 'Heading1'),
        p('Documento comercial de referencia. NO ES UNA FACTURA.'), Spacer(1, 12),
        p(f'Cliente: {c.usuario.get_full_name() or c.usuario.username}'),
        p(f'Fecha: {c.fecha_solicitud:%d/%m/%Y} | Estado: {c.get_estado_display()}'),
        p(f'Vigencia: {c.valida_hasta or "Pendiente de confirmación"}'),
        p(f'Entrega estimada: {c.fecha_entrega_programada or "Por coordinar"}'),
        p(f'Prioridad: {"Urgente" if c.es_urgente else "Normal"}'), Spacer(1, 16),
        p('Especificaciones', 'Heading2'), p(c.producto.nombre if c.producto else 'Trabajo personalizado'),
        p(c.descripcion), Spacer(1, 12)]
    if c.ancho_cm or c.alto_cm:
        story.append(p(f'Medidas: {c.ancho_cm or "-"} x {c.alto_cm or "-"} cm'))
    table = Table([[p('Cantidad'), p('Valor unitario estimado'), p('Total estimado')],
                   [p(c.cantidad), p(unitario), p(total)]], colWidths=[3*cm, 7*cm, 7*cm])
    table.setStyle(TableStyle([('BACKGROUND', (0,0), (-1,0), colors.HexColor('#dceafa')),
        ('VALIGN', (0,0), (-1,-1), 'TOP'), ('BOX', (0,0), (-1,-1), .5, colors.lightgrey),
        ('TOPPADDING', (0,0), (-1,-1), 10), ('BOTTOMPADDING', (0,0), (-1,-1), 10)]))
    story += [table, Spacer(1, 16), p('Condiciones', 'Heading2'), p(c.condiciones),
        Spacer(1, 12), p('El valor unitario se muestra como referencia redondeada. El total aprobado es el valor de la cotización.'),
        p('La aprobación del precio no autoriza a imprimir: el cliente debe aprobar también la última versión del diseño.')]
    def footer(canvas, document):
        canvas.saveState()
        canvas.setFont('Helvetica', 9)
        canvas.drawString(2*cm, 1.2*cm, 'Serigraff | Cotización - No es factura')
        canvas.drawRightString(A4[0]-2*cm, 1.2*cm, f'Página {document.page}')
        canvas.restoreState()
    doc.build(story, onFirstPage=footer, onLaterPages=footer)
    return stream.getvalue()
